'use strict';

const DATA_URL = './data/uniques.json';

const form = document.querySelector('#search-form');
const queryInput = document.querySelector('#query');
const statusElement = document.querySelector('#status');
const resultsTable = document.querySelector('#results-table');
const resultsBody = document.querySelector('#results-body');

let items = [];
let dataLoaded = false;

function setStatus(message, tone = 'default') {
  statusElement.textContent = message;
  if (tone === 'error') {
    statusElement.dataset.tone = 'error';
    return;
  }

  delete statusElement.dataset.tone;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function findHighlightRanges(text, queries) {
  const normalizedText = text.toLowerCase();
  const ranges = [];

  queries.forEach((query) => {
    let startIndex = 0;

    while (startIndex < normalizedText.length) {
      const matchIndex = normalizedText.indexOf(query, startIndex);
      if (matchIndex === -1) {
        break;
      }

      ranges.push([matchIndex, matchIndex + query.length]);
      startIndex = matchIndex + query.length;
    }
  });

  ranges.sort((left, right) => left[0] - right[0] || left[1] - right[1]);

  return ranges.reduce((merged, currentRange) => {
    const lastRange = merged.at(-1);
    if (!lastRange || currentRange[0] > lastRange[1]) {
      merged.push([...currentRange]);
      return merged;
    }

    lastRange[1] = Math.max(lastRange[1], currentRange[1]);
    return merged;
  }, []);
}

function highlightText(text, queries) {
  if (queries.length === 0) {
    return escapeHtml(text);
  }

  const ranges = findHighlightRanges(text, queries);
  if (ranges.length === 0) {
    return escapeHtml(text);
  }

  const parts = [];
  let cursor = 0;

  ranges.forEach(([start, end]) => {
    if (cursor < start) {
      parts.push(escapeHtml(text.slice(cursor, start)));
    }

    parts.push(`<mark>${escapeHtml(text.slice(start, end))}</mark>`);
    cursor = end;
  });

  if (cursor < text.length) {
    parts.push(escapeHtml(text.slice(cursor)));
  }

  return parts.join('');
}

function tokenizeQuery(value) {
  return value
    .trim()
    .split(/\s+/)
    .map((part) => part.trim().toLowerCase())
    .filter(Boolean);
}

function searchItems(queries) {
  return items.filter((item) => {
    const effectText = String(item.effect_text ?? '');
    const normalizedEffectText = effectText.toLowerCase();

    return queries.some((query) => normalizedEffectText.includes(query));
  });
}

function renderRows(results, queries = []) {
  if (results.length === 0) {
    resultsBody.innerHTML = '';
    resultsTable.classList.add('hidden');
    return;
  }

  resultsBody.innerHTML = results
    .map((item) => {
      const name = escapeHtml(item.name);
      const itemType = escapeHtml(item.item_type ?? '');
      const effectText = highlightText(String(item.effect_text ?? ''), queries);
      const url = escapeHtml(item.url ?? '');

      return `
        <tr>
          <td>${name}</td>
          <td>${itemType}</td>
          <td class="effect-text">${effectText}</td>
          <td><a href="${url}" target="_blank" rel="noopener noreferrer">${url}</a></td>
        </tr>
      `;
    })
    .join('');

  resultsTable.classList.remove('hidden');
}

async function loadItems() {
  try {
    const response = await fetch(DATA_URL);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    items = await response.json();
    dataLoaded = true;
    setStatus(`データ読み込み完了: ${items.length} 件。クエリを入力して検索してください。`);
  } catch (error) {
    dataLoaded = false;
    setStatus(`データを読み込めませんでした: ${error.message}`, 'error');
  }
}

function handleSubmit(event) {
  event.preventDefault();

  if (!dataLoaded) {
    setStatus('データ未読込のため検索できません。ページ再読込後も失敗する場合はHTTPサーバー経由で開いてください。', 'error');
    renderRows([]);
    return;
  }

  const rawQuery = queryInput.value;
  const queries = tokenizeQuery(rawQuery);

  if (queries.length === 0) {
    setStatus('検索語を入力してください。空白区切りで複数語を指定できます。');
    renderRows([]);
    return;
  }

  const results = searchItems(queries);
  renderRows(results, queries);

  if (results.length === 0) {
    setStatus(`"${rawQuery}" の検索結果は 0 件でした。`);
    return;
  }

  setStatus(`"${rawQuery}" の検索結果: ${results.length} 件`);
}

form.addEventListener('submit', handleSubmit);
loadItems();
