import assert from 'node:assert/strict';
import { default as worker } from './worker.js';
let calls = 0;
const realFetch = globalThis.fetch;
globalThis.fetch = async (url, options) => {
  calls++;
  assert.equal(options.headers.Authorization, 'Bearer test-token');
  const second = new URL(url).searchParams.get('offset');
  if (!second) return Response.json({
    records: [{ fields: {
      RecipeID: 'simple-salad', Name: 'Simple salad', Country: 'Italy', Region: 'Europe',
      Verified: false, Draft: true, Minutes: 10, Servings: 2,
      IngredientsJSON: '[{"name":"tomato","quantity":1,"amount":"","category":"Fruit & Vegetables"}]',
      StepsJSON: '["Chop tomato"]', MealsJSON: '["Lunch"]'
    }}], offset: 'page-two'
  });
  return Response.json({ records: [{ fields: {
    RecipeID: 'pizza', Name: 'Pizza', Verified: true, Minutes: 30,
    IngredientsJSON: '[]', StepsJSON: '[]'
  }}] });
};
try {
  const response = await worker.fetch(new Request('https://bite.example/recipes'), {
    AIRTABLE_TOKEN:'test-token',AIRTABLE_BASE_ID:'appTest',AIRTABLE_TABLE_ID:'tblTest'
  });
  assert.equal(response.status, 200);
  const { recipes } = await response.json();
  assert.equal(calls, 2);
  assert.equal(recipes.length, 2);
  assert.equal(recipes[0].ingredients[0].name, 'tomato');
  assert.equal(recipes[0].draft, true);
  assert.equal(recipes[1].verified, true);
  const missing = await worker.fetch(new Request('https://bite.example/recipes'), {});
  assert.equal(missing.status, 503);
  console.log('PASS: worker Airtable pagination, decoding, and missing-credentials error');
} finally {
  globalThis.fetch = realFetch;
}
