// Survey of the JS sources: globals, free identifiers, member/method names.
const fs = require('fs'), path = require('path');
const acorn = require('acorn'), walk = require('acorn-walk');
const ROOT = path.resolve(__dirname, '../..');
const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
const files = [...html.matchAll(/<script src="([^"]+)"/g)].map(m => m[1]);
const globals = {}; const dup = [];
const asts = {};
for (const f of files) {
  const src = fs.readFileSync(path.join(ROOT, f), 'utf8');
  const ast = acorn.parse(src, { ecmaVersion: 'latest', sourceType: 'script', locations: true });
  asts[f] = ast;
  for (const n of ast.body) {
    const add = (name, kind) => { if (globals[name]) dup.push(`${name}: ${globals[name].file} -> ${f}`); globals[name] = { file: f, kind }; };
    if (n.type === 'FunctionDeclaration') add(n.id.name, 'func');
    else if (n.type === 'VariableDeclaration') for (const d of n.declarations) { if (d.id.type === 'Identifier') add(d.id.name, n.kind); else console.log('destructured global', f, n.loc.start.line); }
  }
}
const mode = process.argv[2] || 'summary';
const methodCalls = {}, props = {}, objMethods = {}, nodeTypes = {}, calleeKinds = {};
for (const f of files) {
  walk.full(asts[f], n => {
    nodeTypes[n.type] = (nodeTypes[n.type] || 0) + 1;
    if (n.type === 'CallExpression' && n.callee.type === 'MemberExpression' && !n.callee.computed) {
      const k = n.callee.property.name; methodCalls[k] = (methodCalls[k] || 0) + 1;
    }
    if (n.type === 'MemberExpression' && !n.computed) { const k = n.property.name; props[k] = (props[k] || 0) + 1; }
    if (n.type === 'Property' && (n.method || (n.value && /Function/.test(n.value.type)))) { const k = n.key.name || n.key.value; objMethods[k] = (objMethods[k] || 0) + 1; }
    if (n.type === 'Property' && n.kind !== 'init') console.log('accessor', f, n.loc.start.line, n.key.name);
  });
}
const show = (o, min = 1) => Object.entries(o).filter(e => e[1] >= min).sort((a, b) => b[1] - a[1]).map(e => e[0] + ':' + e[1]).join(' ');
if (mode === 'summary') {
  console.log('FILES', files.length, 'GLOBALS', Object.keys(globals).length);
  console.log('DUPS\n' + dup.join('\n'));
  console.log('\nNODE TYPES\n' + show(nodeTypes));
  console.log('\nMETHOD CALLS\n' + show(methodCalls));
  console.log('\nOBJ METHODS\n' + show(objMethods));
}
if (mode === 'props') console.log(show(props));
