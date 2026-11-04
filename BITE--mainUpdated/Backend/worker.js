/**
 * Read-only Airtable -> BITE! recipe bridge.
 * Never put AIRTABLE_TOKEN in iOS source or Info.plist.
 * Set it using: npx wrangler secret put AIRTABLE_TOKEN
 */
const jsonHeaders = {
  'Content-Type': 'application/json; charset=utf-8',
  'Access-Control-Allow-Origin': '*',
  'Cache-Control': 'public, max-age=300'
};

function getJSON(value, fallback) {
  try {
    if (Array.isArray(value)) return value;
    if (typeof value === 'string' && value.length) return JSON.parse(value);
    return fallback;
  } catch { return fallback; }
}

function toRecipe(record) {
  const f = record.fields || {};
  const id = String(f.RecipeID || '');
  const name = String(f.Name || '');
  if (!id || !name) return null;
  let hash = 0;
  for (const char of id) hash = (hash * 31 + char.codePointAt(0)) % 100;
  return {
    id, name,
    minutes: Math.max(0, Number(f.Minutes || 0)),
    tag: String(f.Category || 'Main'),
    servings: Math.max(1, Number(f.Servings || 1)),
    emoji: String(f.Emoji || '🍽️'),
    hue: hash / 100,
    blurb: String(f.Description || ''),
    verified: f.Verified === true,
    draft: f.Draft === true,
    sourceUrl: null,
    meals: getJSON(f.MealsJSON, ['Lunch', 'Dinner']),
    ingredients: getJSON(f.IngredientsJSON, []),
    steps: getJSON(f.StepsJSON, []),
    intolerances: getJSON(f.IntolerancesJSON, []),
    allergens: getJSON(f.AllergensJSON, []),
    diets: getJSON(f.DietsJSON, []),
    goals: getJSON(f.GoalsJSON, []),
    costPerServing: Number(f.CostPerServing || 3),
    region: String(f.Region || ''),
    country: String(f.Country || ''),
    vibes: getJSON(f.VibesJSON, []),
    imageURL: typeof f.ImageURL === 'string' && /^https:\/\//.test(f.ImageURL) ? f.ImageURL : null
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      }});
    }
    if (request.method !== 'GET' || url.pathname !== '/recipes') {
      return Response.json({ error: 'Not found' }, { status: 404, headers: jsonHeaders });
    }
    if (!env.AIRTABLE_TOKEN || !env.AIRTABLE_BASE_ID || !env.AIRTABLE_TABLE_ID) {
      return Response.json({ error: 'Airtable credentials not configured' }, { status: 503, headers: jsonHeaders });
    }
    try {
      const records = [];
      let offset;
      do {
        const api = new URL(`https://api.airtable.com/v0/${env.AIRTABLE_BASE_ID}/${env.AIRTABLE_TABLE_ID}`);
        api.searchParams.set('pageSize', '100');
        if (offset) api.searchParams.set('offset', offset);
        const response = await fetch(api, {
          headers: { Authorization: `Bearer ${env.AIRTABLE_TOKEN}`, Accept: 'application/json' }
        });
        if (!response.ok) throw new Error(`Airtable HTTP ${response.status}`);
        const page = await response.json();
        records.push(...(page.records || []));
        offset = page.offset;
        if (records.length > 10000) throw new Error('Too many records');
      } while (offset);
      const recipes = records.map(toRecipe).filter(Boolean);
      return Response.json({ recipes }, { status: 200, headers: jsonHeaders });
    } catch (error) {
      return Response.json({ error: 'Unable to read recipe catalog' }, { status: 502, headers: jsonHeaders });
    }
  }
};
