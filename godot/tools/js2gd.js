#!/usr/bin/env node
// js2gd — converts the Wizard's League JavaScript sources into GDScript modules.
// Usage: node js2gd.js            (writes ../game/*.gd)
//        node js2gd.js --only=helpers
const fs = require('fs'), path = require('path');
const acorn = require('acorn');

const ROOT = path.resolve(__dirname, '../..');
const OUT = path.resolve(__dirname, '../game');
const GN = JSON.parse(fs.readFileSync(path.join(__dirname, 'godot_names.json'), 'utf8'));

// ───────────────────────────── module naming ─────────────────────────────
const SPECIAL_MOD = { map: 'MapLogic', ui: 'UI', mp3audio: 'Mp3Audio', version: 'Version' };
function modName(file) {
  const b = path.basename(file, '.js');
  if (SPECIAL_MOD[b]) return SPECIAL_MOD[b];
  return b.split(/[_\-]/).map(p => p[0].toUpperCase() + p.slice(1)).join('');
}

// ───────────────────────────── reserved names ─────────────────────────────
const KEYWORDS = new Set(('if elif else for while match when break continue pass return class class_name extends is in as self super signal func static const enum var breakpoint preload await yield assert void PI TAU INF NAN and or not true false null namespace trait ' +
  'abs acos asin atan atan2 ceil clamp cos exp floor fmod lerp log max min pow randf randi round sign sin snapped sqrt step str tan wrap len range print load char typeof weakref hash seed ease smoothstep remap pingpong convert floori ceili roundi absi absf signi signf clampi clampf mini maxi minf maxf posmod fposmod randomize printerr prints printt wrapi wrapf lerpf is_nan is_inf is_same type tool export onready get set call free connect emit notification duplicate name position scale owner').split(' '));
const NODE_MEMBERS = new Set(GN.node);
const CLASSES = new Set(GN.classes);
function safeLocal(n) { if (n === '_') return '_u'; return (KEYWORDS.has(n) || CLASSES.has(n)) ? n + '_' : n; }
function safeGlobal(n) { return (KEYWORDS.has(n) || NODE_MEMBERS.has(n) || CLASSES.has(n)) ? n + '_' : n; }
const PROP_KEYWORDS = new Set('if elif else for while match when break continue pass return class class_name extends is in as self super signal func static const enum var breakpoint preload await yield assert void and or not true false null namespace trait'.split(' '));

// ───────────────────────────── source patches ─────────────────────────────
// Textual fixes applied to the JS before parsing (see patches.js).
const PATCHES = fs.existsSync(path.join(__dirname, 'patches.js')) ? require('./patches.js') : {};
// Hand-written GDScript replacing whole functions (see overrides/).
const OVERRIDES = {};
const ovDir = path.join(__dirname, 'overrides');
if (fs.existsSync(ovDir)) for (const f of fs.readdirSync(ovDir)) {
  if (!f.endsWith('.gd')) continue;
  const [mod, fn] = f.replace(/\.gd$/, '').split('.');
  (OVERRIDES[mod] = OVERRIDES[mod] || {})[fn] = fs.readFileSync(path.join(ovDir, f), 'utf8');
}

// ───────────────────────────── load sources ─────────────────────────────
const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
const FILES = [...html.matchAll(/<script src="([^"]+)"/g)].map(m => m[1]);
const mods = [];
const GLOBALS = new Map(); // name -> {mod, kind, node}
const REASSIGNED = new Set();
const warnings = [];
function warn(mod, node, msg) { warnings.push(`${mod.file}:${node && node.loc ? node.loc.start.line : '?'}: ${msg}`); }

for (const file of FILES) {
  let src = fs.readFileSync(path.join(ROOT, file), 'utf8');
  for (const p of (PATCHES[file] || [])) {
    if (!src.includes(p[0])) { console.error(`PATCH MISS ${file}: ${p[0].slice(0, 60)}`); continue; }
    src = p[2] ? src.split(p[0]).join(p[1]) : src.replace(p[0], () => p[1]);
  }
  const comments = [];
  const ast = acorn.parse(src, { ecmaVersion: 'latest', sourceType: 'script', locations: true, onComment: comments });
  const mod = { file, name: modName(file), src, ast, comments, funcs: new Map(), vars: new Map(), privates: new Map(), exports: new Map() };
  collectReassigned(ast);
  mods.push(mod);
}
// Unwrap `(function(){ ... })();` module wrappers and turn function-valued consts /
// `window.X = function` exports into ordinary declarations.
function collectReassigned(ast) {
  (function w(n) {
    if (!n || typeof n.type !== 'string') return;
    if (n.type === 'AssignmentExpression') {
      if (n.left.type === 'Identifier') REASSIGNED.add(n.left.name);
      if (n.left.type === 'MemberExpression' && !n.left.computed && n.left.object.type === 'Identifier' && n.left.object.name === 'window') REASSIGNED.add('window.' + n.left.property.name);
    }
    for (const k in n) { if (k === 'loc') continue; const v = n[k]; if (Array.isArray(v)) v.forEach(w); else if (v && typeof v.type === 'string') w(v); }
  })(ast);
}
function normalizeTop(mod) {
  const out = [];
  const asDecl = (name, fn, node) => {
    let body = fn.body;
    if (body.type !== 'BlockStatement') body = { type: 'BlockStatement', body: [{ type: 'ReturnStatement', argument: body, start: body.start, end: body.end, loc: body.loc }], start: body.start, end: body.end, loc: body.loc };
    return { type: 'FunctionDeclaration', id: { type: 'Identifier', name, start: node.start, end: node.start, loc: node.loc }, params: fn.params, body, start: node.start, end: node.end, loc: node.loc, _wasArrow: fn.type === 'ArrowFunctionExpression' };
  };
  const usesThisOrSelf = (fn) => false;
  const handle = (s, priv) => {
    // (function(){ ... })();
    if (s.type === 'ExpressionStatement' && s.expression.type === 'CallExpression' && isFnNode(s.expression.callee) && !s.expression.arguments.length && !s.expression.callee.params.length && s.expression.callee.body.type === 'BlockStatement' && s.expression.callee.body.body.length > 3) {
      for (const c of s.expression.callee.body.body) handle(c, true);
      return;
    }
    // window.X = function(...) {...}
    if (s.type === 'ExpressionStatement' && s.expression.type === 'AssignmentExpression' && s.expression.operator === '=' && s.expression.left.type === 'MemberExpression' && !s.expression.left.computed &&
        s.expression.left.object.type === 'Identifier' && s.expression.left.object.name === 'window' && isFnNode(s.expression.right)) {
      const d = asDecl(s.expression.left.property.name, s.expression.right, s); d._topFnExport = true; out.push(d); return;
    }
    if (s.type === 'VariableDeclaration') {
      // const f = (..) => ..   → function declaration (when never reassigned)
      const fnDecls = s.declarations.filter(d => d.id.type === 'Identifier' && d.init && isFnNode(d.init) && s.kind === 'const');
      if (fnDecls.length === s.declarations.length) { for (const d of fnDecls) { const fd = asDecl(d.id.name, d.init, s); fd._private = priv; out.push(fd); } return; }
    }
    if (priv && (s.type === 'FunctionDeclaration' || s.type === 'VariableDeclaration')) s._private = true;
    out.push(s);
  };
  for (const s of mod.ast.body) handle(s, false);
  mod.ast.body = out;
}
function isFnNode(n) { return n && (n.type === 'FunctionExpression' || n.type === 'ArrowFunctionExpression'); }
for (const mod of mods) normalizeTop(mod);
// Function declarations that some code later replaces (`fn = function…`) must be variables.
for (const mod of mods) mod.ast.body = mod.ast.body.map(n => {
  if (n.type !== 'FunctionDeclaration') return n;
  const nm = n.id.name;
  if (!(REASSIGNED.has(nm) && !n._topFnExport) && !REASSIGNED.has('window.' + nm)) return n;
  if (n._topFnExport && !REASSIGNED.has(nm)) return n;
  return { type: 'VariableDeclaration', kind: 'let', start: n.start, end: n.end, loc: n.loc, _private: n._private, _swappable: true,
    declarations: [{ type: 'VariableDeclarator', id: n.id, init: Object.assign({}, n, { type: 'FunctionExpression', id: null }), start: n.start, end: n.end, loc: n.loc }] };
});
// Later definitions win (script load order), matching the browser.
for (const mod of mods) {
  for (const n of mod.ast.body) {
    const reg = (name, info) => { if (n._private) mod.privates.set(name, info); else GLOBALS.set(name, info); };
    if (n.type === 'FunctionDeclaration') { reg(n.id.name, { mod, kind: 'func', node: n }); mod.funcs.set(n.id.name, n); }
    else if (n.type === 'VariableDeclaration') for (const d of n.declarations) {
      if (d.id.type !== 'Identifier') { warn(mod, n, 'destructured global'); continue; }
      const isFn = d.init && /Function/.test(d.init.type);
      const lit = n.kind === 'const' && d.init && (d.init.type === 'Literal' || d.init.type === 'TemplateLiteral') ? (d.init.type === 'TemplateLiteral' ? 'string' : typeof d.init.value === 'string' ? 'string' : typeof d.init.value === 'number' ? 'number' : null) : null;
      reg(d.id.name, { mod, kind: 'var', node: d, isFn, constType: lit });
      mod.vars.set(d.id.name, d);
    }
  }
}
function lookupGlobal(name, mod) { return (mod && mod.privates.get(name)) || GLOBALS.get(name); }
// ── property classification ──
// A property that may be absent on some objects is read through .get() (yielding null, like
// JavaScript's undefined) instead of plain dot access, which is an error in GDScript.
const LITERAL_KEYS = new Set(), OPTIONAL_KEYS = new Set();
const SHIM_PROPS = new Set(('id className classList style innerHTML outerHTML textContent innerText value checked disabled hidden title dataset children childNodes ' +
  'parentElement parentNode firstChild lastChild firstElementChild lastElementChild nextElementSibling previousElementSibling nextSibling tagName nodeType ' +
  'offsetWidth offsetHeight offsetLeft offsetTop offsetParent clientWidth clientHeight scrollTop scrollLeft scrollHeight scrollWidth width height isConnected ' +
  'draggable placeholder type target currentTarget clientX clientY pageX pageY offsetX offsetY button buttons key code touches changedTouches deltaY deltaX ' +
  'pointerId pointerType dataTransfer detail shiftKey ctrlKey altKey metaKey defaultPrevented canvas fillStyle strokeStyle lineWidth globalAlpha font textAlign ' +
  'textBaseline shadowColor shadowBlur lineCap lineJoin innerWidth innerHeight devicePixelRatio body head documentElement activeElement volume paused currentTime ' +
  'loop muted src duration size length cssText').split(' '));
function classifyProps() {
  const keysOf = o => o.properties.filter(p => p.type === 'Property' && !p.computed).map(p => p.key.name != null ? p.key.name : String(p.key.value));
  const family = (objs) => {
    if (objs.length < 2) return;
    const sets = objs.map(o => new Set(keysOf(o)));
    const all = new Set(); sets.forEach(st => st.forEach(k => all.add(k)));
    for (const k of all) if (sets.some(st => !st.has(k))) OPTIONAL_KEYS.add(k);
  };
  const objsIn = (n) => n.type === 'ArrayExpression' ? n.elements.filter(e => e && e.type === 'ObjectExpression')
    : n.type === 'ObjectExpression' ? n.properties.filter(p => p.type === 'Property' && p.value.type === 'ObjectExpression').map(p => p.value) : [];
  for (const mod of mods) (function w(n) {
    if (!n || typeof n.type !== 'string') return;
    if (n.type === 'ObjectExpression') {
      keysOf(n).forEach(k => LITERAL_KEYS.add(k));
      // values that are arrays of objects (PASSIVE_CHOICES = {Fire:[…], Water:[…]}) form one family
      const cousins = [];
      for (const p of n.properties) if (p.type === 'Property' && p.value.type === 'ArrayExpression') cousins.push(...objsIn(p.value));
      family(cousins);
    }
    if (n.type === 'ArrayExpression' || n.type === 'ObjectExpression') family(objsIn(n));
    for (const k in n) { if (k === 'loc') continue; const v = n[k]; if (Array.isArray(v)) v.forEach(w); else if (v && typeof v.type === 'string') w(v); }
  })(mod.ast);
}
function missingProne(p) { return !SHIM_PROPS.has(p) && (!LITERAL_KEYS.has(p) || OPTIONAL_KEYS.has(p)); }
// window.X = ... / bare assignments to undeclared names become globals of the Win module
const WINDOW_PROPS = new Set();

// ───────────────────────────── helpers ─────────────────────────────
const T = '\t';
function ind(s, n = 1) { const p = T.repeat(n); return s.split('\n').map(l => l.length ? p + l : l).join('\n'); }
function strLit(s) {
  let out = '"';
  for (const ch of s) {
    const c = ch.codePointAt(0);
    if (ch === '"') out += '\\"'; else if (ch === '\\') out += '\\\\';
    else if (ch === '\n') out += '\\n'; else if (ch === '\r') out += '\\r'; else if (ch === '\t') out += '\\t';
    else if (c < 32 || c === 0x2028 || c === 0x2029) out += '\\u' + c.toString(16).padStart(4, '0');
    else out += ch;
  }
  return out + '"';
}
function numLit(v, raw) {
  if (Number.isInteger(v) && Math.abs(v) < 2 ** 53) {
    if (raw && /^0[xX]/.test(raw)) return raw;
    if (raw && /[.eE]/.test(raw) && !/^0[xX]/.test(raw)) return String(v) + '.0';
    return String(v);
  }
  let s = String(v);
  if (/e/.test(s) && !/\./.test(s)) s = s.replace('e', '.0e');
  return s;
}
function isSimple(n) { // cheap + side-effect free
  if (!n) return true;
  switch (n.type) {
    case 'Literal': return !n.regex;
    case 'Identifier': case 'ThisExpression': return true;
    case 'TemplateLiteral': return n.expressions.every(isSimple);
    case 'MemberExpression': return isSimple(n.object) && (!n.computed || isSimple(n.property));
    case 'UnaryExpression': return n.operator !== 'delete' && isSimple(n.argument);
    case 'ArrayExpression': return n.elements.length === 0;
    case 'ObjectExpression': return n.properties.length === 0;
    case 'BinaryExpression': return isSimple(n.left) && isSimple(n.right);
    case 'ChainExpression': return isSimple(n.expression);
  }
  return false;
}
const STRINGY_PROPS = new Set('name emoji desc title id label icon element color text innerHTML textContent cssText className html tag detail negative type rarity key tier outerHTML value placeholder fillStyle strokeStyle font'.split(' '));
const BOOL_METHODS = new Set('includes has some every startsWith endsWith isArray contains test hasOwnProperty isInteger'.split(' '));
const STR_METHODS = new Set('toFixed join toUpperCase toLowerCase trim repeat replace toString padStart padEnd charAt substring substr toLocaleString toLocaleDateString'.split(' '));

// Methods that exist natively on runtime shim objects (DOM nodes, canvas context, sets, …)
const NATIVE_METHODS = new Set(('getElementById createElement createElementNS createTextNode querySelector querySelectorAll appendChild removeChild insertBefore insertAdjacentHTML remove ' +
  'addEventListener removeEventListener setAttribute getAttribute removeAttribute hasAttribute getBoundingClientRect getContext focus blur click scrollIntoView scrollTo setPointerCapture releasePointerCapture closest contains cloneNode ' +
  'add toggle setProperty getPropertyValue removeProperty preventDefault stopPropagation stopImmediatePropagation observe disconnect unobserve play pause load ' +
  'fillRect strokeRect clearRect beginPath closePath moveTo lineTo arc arcTo ellipse rect roundRect bezierCurveTo quadraticCurveTo fill stroke clip save restore translate rotate scale setTransform resetTransform transform ' +
  'createLinearGradient createRadialGradient addColorStop fillText strokeText measureText drawImage setLineDash ' +
  'has delete clear getItem setItem removeItem then catch').split(' '));

// ───────────────────────────── scope analysis ─────────────────────────────
class Scope {
  constructor(parent, fn, kind, node) { this.parent = parent; this.fn = fn; this.kind = kind; this.node = node; this.b = new Map(); this.children = []; if (parent) parent.children.push(this); }
  lookup(name) { for (let s = this; s; s = s.parent) if (s.b.has(name)) return s.b.get(name); return null; }
}
let _bid = 0;
function mkBinding(name, kind, scope, node) {
  return { id: ++_bid, name, kind, scope, fn: scope.fn, node, assigns: 0, refs: [], declPos: node ? node.start : 0, declEnd: node ? node.end : 0, boxed: false, hoist: false, gd: null, type: null, typeConflict: false, loopVar: false };
}
function patternNames(p, out = []) {
  if (!p) return out;
  switch (p.type) {
    case 'Identifier': out.push(p); break;
    case 'ObjectPattern': p.properties.forEach(pr => patternNames(pr.type === 'RestElement' ? pr.argument : pr.value, out)); break;
    case 'ArrayPattern': p.elements.forEach(e => patternNames(e, out)); break;
    case 'AssignmentPattern': patternNames(p.left, out); break;
    case 'RestElement': patternNames(p.argument, out); break;
  }
  return out;
}
const isFn = n => n && (n.type === 'FunctionDeclaration' || n.type === 'FunctionExpression' || n.type === 'ArrowFunctionExpression');

// Analyse one top-level function (or the module body). Fills node._scope, id._b.
function analyze(root, mod) {
  const allBindings = [];
  function declare(scope, idNode, kind, declNode) {
    const name = idNode.name;
    if (scope.b.has(name)) { const b = scope.b.get(name); idNode._b = b; return b; }
    const b = mkBinding(name, kind, scope, declNode || idNode);
    scope.b.set(name, b); allBindings.push(b); idNode._b = b; return b;
  }
  function fnScopeOf(scope) { let s = scope; while (s.kind !== 'function') s = s.parent; return s; }
  // hoist var + function declarations
  function hoistDecls(node, fscope, topBlockScope, inNestedBlock) {
    if (!node || typeof node.type !== 'string') return;
    if (isFn(node)) return;
    if (node.type === 'VariableDeclaration' && node.kind === 'var') {
      for (const d of node.declarations) for (const id of patternNames(d.id)) { const b = declare(fscope, id, 'var', d); if (inNestedBlock) b.hoist = true; }
    }
    for (const k in node) {
      if (k === 'loc' || k[0] === '_') continue;
      const v = node[k];
      if (Array.isArray(v)) v.forEach(c => c && typeof c.type === 'string' && hoistDecls(c, fscope, topBlockScope, inNestedBlock || node.type !== 'Program' && node !== fscope.node.body));
      else if (v && typeof v.type === 'string') hoistDecls(v, fscope, topBlockScope, inNestedBlock || (node !== fscope.node.body && node.type !== 'Program'));
    }
  }
  function declareBlock(body, scope) { // let/const/function at this block level
    for (const s of body) {
      if (s.type === 'VariableDeclaration' && s.kind !== 'var') for (const d of s.declarations) for (const id of patternNames(d.id)) declare(scope, id, s.kind, d);
      if (s.type === 'FunctionDeclaration') { const b = declare(scope, s.id, 'function', s); b.fnNode = s; }
    }
  }
  function ref(idNode, scope, isAssign, extra) {
    const b = scope.lookup(idNode.name);
    if (!b) return;
    idNode._b = b;
    b.refs.push({ node: idNode, scope, fn: scope.fn, pos: idNode.start });
    if (isAssign) { if (extra && extra.loopUpdate) b.loopAssigns = (b.loopAssigns || 0) + 1; else b.assigns++; }
  }
  function visitPatternAssign(p, scope) {
    if (!p) return;
    if (p.type === 'Identifier') ref(p, scope, true);
    else if (p.type === 'MemberExpression') visit(p, scope);
    else if (p.type === 'ObjectPattern') p.properties.forEach(pr => visitPatternAssign(pr.value || pr.argument, scope));
    else if (p.type === 'ArrayPattern') p.elements.forEach(e => visitPatternAssign(e, scope));
    else if (p.type === 'AssignmentPattern') { visitPatternAssign(p.left, scope); visit(p.right, scope); }
  }
  function visitFn(node, scope) {
    const fs_ = new Scope(scope, node, 'function', node);
    node._scope = fs_; fs_.fn = node; node._parentFn = scope.fn;
    for (const p of node.params) for (const id of patternNames(p)) { const b = declare(fs_, id, 'param', id); b.declEnd = node.body.start; b.declPos = node.start; }
    if (node.type === 'FunctionExpression' && node.id) { const b = declare(fs_, node.id, 'selfname', node.id); b.boxed = true; b.declared = true; node._selfB = b; }
    if (node.body.type === 'BlockStatement') {
      hoistDecls(node.body, fs_, fs_, false);
      declareBlock(node.body.body, fs_);
      node.body._scope = fs_;
      node.body.body.forEach(s => visit(s, fs_));
    } else visit(node.body, fs_);
    for (const p of node.params) if (p.type === 'AssignmentPattern') visit(p.right, fs_);
  }
  function visit(node, scope, extra) {
    if (!node) return;
    switch (node.type) {
      case 'Identifier': ref(node, scope, false); return;
      case 'FunctionDeclaration': visitFn(node, scope); return;
      case 'FunctionExpression': case 'ArrowFunctionExpression': visitFn(node, scope); return;
      case 'BlockStatement': {
        const s = new Scope(scope, scope.fn, 'block', node); node._scope = s;
        declareBlock(node.body, s); node.body.forEach(c => visit(c, s)); return;
      }
      case 'ForStatement': {
        const s = new Scope(scope, scope.fn, 'block', node); node._scope = s;
        if (node.init && node.init.type === 'VariableDeclaration' && node.init.kind !== 'var')
          for (const d of node.init.declarations) for (const id of patternNames(d.id)) { const b = declare(s, id, node.init.kind, d); b.loopVar = true; }
        visit(node.init, s); visit(node.test, s); visit(node.update, s, { loopUpdate: true }); visit(node.body, s); return;
      }
      case 'ForInStatement': case 'ForOfStatement': {
        const s = new Scope(scope, scope.fn, 'block', node); node._scope = s;
        if (node.left.type === 'VariableDeclaration') {
          if (node.left.kind !== 'var') for (const d of node.left.declarations) for (const id of patternNames(d.id)) { const b = declare(s, id, node.left.kind, d); b.loopVar = true; }
        } else visitPatternAssign(node.left, s);
        visit(node.right, s); visit(node.body, s); return;
      }
      case 'SwitchStatement': {
        visit(node.discriminant, scope);
        const s = new Scope(scope, scope.fn, 'block', node); node._scope = s;
        node.cases.forEach(c => declareBlock(c.consequent, s));
        node.cases.forEach(c => { visit(c.test, s); c.consequent.forEach(x => visit(x, s)); }); return;
      }
      case 'CatchClause': {
        const s = new Scope(scope, scope.fn, 'block', node); node._scope = s;
        if (node.param) for (const id of patternNames(node.param)) declare(s, id, 'let', id);
        visit(node.body, s); return;
      }
      case 'VariableDeclaration':
        for (const d of node.declarations) {
          for (const id of patternNames(d.id)) { const b = scope.lookup(id.name); if (b) { id._b = b; if (d.init && b.kind === 'var' && b.node !== d) b.assigns++; if (d.init && b.kind === 'var' && b.hoist) b.assigns++; } }
          if (d.init) { visit(d.init, scope); noteType(d.id, d.init); }
        }
        return;
      case 'AssignmentExpression':
        if (node.left.type === 'Identifier') { ref(node.left, scope, true, extra); noteType(node.left, node.right, node.operator); }
        else visitPatternAssign(node.left, scope);
        visit(node.right, scope); return;
      case 'UpdateExpression':
        if (node.argument.type === 'Identifier') ref(node.argument, scope, true, extra); else visit(node.argument, scope); return;
      case 'MemberExpression': visit(node.object, scope); if (node.computed) visit(node.property, scope); return;
      case 'Property': if (node.computed) visit(node.key, scope); visit(node.value, scope); return;
      case 'LabeledStatement': visit(node.body, scope); return;
      case 'BreakStatement': case 'ContinueStatement': return;
      case 'SequenceExpression': node.expressions.forEach(e => visit(e, scope, extra)); return;
    }
    for (const k in node) {
      if (k === 'loc' || k[0] === '_' || k === 'type') continue;
      const v = node[k];
      if (Array.isArray(v)) v.forEach(c => c && typeof c.type === 'string' && visit(c, scope));
      else if (v && typeof v.type === 'string') visit(v, scope);
    }
  }
  function noteType(idNode, init, op) {
    if (idNode.type !== 'Identifier' || !idNode._b) return;
    const b = idNode._b; const t = inferType(init);
    const nt = (op === '+=' && b.type === 'string') ? 'string' : t;
    if (b.type == null && !b.typeSet) { b.type = nt; b.typeSet = true; }
    else if (b.type !== nt) { b.type = null; }
  }
  const top = new Scope(null, root, 'function', root);
  root._scope = top;
  if (root.type === 'Program') {
    // module body: top-level declarations are globals, not locals
    root.body.forEach(s => { if (s.type === 'FunctionDeclaration') visitFn(s, top); else visit(s, top); });
  } else {
    // re-use visitFn's logic but with a root scope
    const holder = new Scope(null, null, 'function', null);
    visitFn(root, holder);
  }
  // ── boxing decisions ──
  function outermostClosure(refFn, declFn) { let f = refFn; while (f && f._parentFn !== declFn) f = f._parentFn; return f; }
  function creationPos(fnNode) {
    if (fnNode.type === 'FunctionDeclaration' && fnNode.id && fnNode.id._b && fnNode.id._b.hoist) return fnNode.id._b.scope.node ? (fnNode.id._b.scope.node.body ? (fnNode.id._b.scope.node.body.start != null ? fnNode.id._b.scope.node.body.start : fnNode.id._b.scope.node.start) : fnNode.id._b.scope.node.start) : 0;
    return fnNode.start;
  }
  // function declarations referenced before their position get hoisted to the top of their scope
  for (const b of allBindings) if (b.kind === 'function') {
    if (b.refs.some(r => r.pos < b.declPos && r.node !== b.node)) b.hoist = true;
    // captured by an earlier-created closure also needs hoisting or boxing → box handles it
  }
  let changed = true, guard = 0;
  while (changed && guard++ < 10) {
    changed = false;
    for (const b of allBindings) {
      if (b.boxed) continue;
      const nested = b.refs.filter(r => r.fn !== b.fn);
      if (!nested.length) continue;
      const mutated = b.assigns > 0 || (b.kind !== 'param' && b.kind !== 'function' && b.node && b.node.type === 'VariableDeclarator' && !b.node.init && !b.loopVar);
      let early = false;
      const effEnd = (b.kind === 'function' && b.hoist) ? -1 : b.declEnd;
      for (const r of nested) {
        const oc = outermostClosure(r.fn, b.fn); if (!oc) continue;
        const cp = creationPos(oc);
        if (b.kind === 'function') { if (cp <= b.declEnd && (cp < b.declPos || oc === b.fnNode || (oc.start >= b.declPos && oc.end <= b.declEnd))) early = true; if (b.hoist && cp < b.declPos) early = true; }
        else if (cp < effEnd) early = true;
      }
      if (mutated || early) { b.boxed = true; changed = true; }
    }
  }
  return allBindings;
}

// ───────────────────────────── type inference ─────────────────────────────
function inferType(n) {
  if (!n) return null;
  switch (n.type) {
    case 'Literal': return typeof n.value === 'string' ? 'string' : typeof n.value === 'number' ? 'number' : typeof n.value === 'boolean' ? 'bool' : null;
    case 'TemplateLiteral': return 'string';
    case 'BinaryExpression':
      if (n.operator === '+') { const a = inferType(n.left), b = inferType(n.right); if (a === 'string' || b === 'string') return 'string'; if (a === 'number' && b === 'number') return 'number'; return null; }
      if (['-', '*', '/', '%', '**', '|', '&', '^', '<<', '>>', '>>>'].includes(n.operator)) return 'number';
      return 'bool';
    case 'UnaryExpression': return n.operator === '!' ? 'bool' : n.operator === 'typeof' ? 'string' : (n.operator === '-' || n.operator === '+') ? 'number' : null;
    case 'LogicalExpression': {
      const a = inferType(n.left), b = inferType(n.right);
      if (a === 'bool' && b === 'bool') return 'bool';
      if (n.operator !== '&&' && b === 'string' && (a === 'string' || a == null)) return 'string';
      if (n.operator !== '&&' && b === 'number' && (a === 'number' || a == null)) return 'number';
      return null;
    }
    case 'ConditionalExpression': { const a = inferType(n.consequent), b = inferType(n.alternate); return a === b ? a : null; }
    case 'AssignmentExpression': return inferType(n.right);
    case 'Identifier': {
      if (n._b) return n._b.type;
      const g = GLOBALS.get(n.name) || (CUR_MOD && CUR_MOD.privates.get(n.name));
      return g && g.constType ? g.constType : null;
    }
    case 'MemberExpression': if (!n.computed) { if (n.property.name === 'length' || n.property.name === 'size') return 'number'; } return null;
    case 'CallExpression': {
      const c = n.callee;
      if (c.type === 'MemberExpression' && !c.computed) {
        const m = c.property.name;
        if (c.object.type === 'Identifier' && c.object.name === 'Math') return 'number';
        if (BOOL_METHODS.has(m)) return 'bool';
        if (STR_METHODS.has(m)) return 'string';
        if (m === 'indexOf' || m === 'findIndex' || m === 'push' || m === 'charCodeAt') return 'number';
      }
      if (c.type === 'Identifier') {
        if (c.name === 'String') return 'string';
        if (c.name === 'parseInt' || c.name === 'parseFloat' || c.name === 'Number') return 'number';
        if (c.name === 'Boolean' || c.name === 'isNaN') return 'bool';
        const g = !c._b && (GLOBALS.get(c.name) || (CUR_MOD && CUR_MOD.privates.get(c.name)));
        if (g && g.kind === 'func') return g.retType || null;
      }
      return null;
    }
  }
  return null;
}
function isStringy(n) {
  if (inferType(n) === 'string') return true;
  if (n.type === 'MemberExpression' && !n.computed && STRINGY_PROPS.has(n.property.name)) return true;
  if (n.type === 'LogicalExpression' && n.operator === '||' && isStringy(n.right)) return true;
  if (n.type === 'ConditionalExpression' && isStringy(n.consequent) && isStringy(n.alternate)) return true;
  return false;
}
// return-type inference for global functions (bool / string / number)
let CUR_MOD = null;
function inferReturnTypes() {
  const all = [...GLOBALS.values()]; for (const m of mods) all.push(...m.privates.values());
  for (let pass = 0; pass < 3; pass++) for (const g of all) {
    CUR_MOD = g.mod;
    if (g.kind !== 'func') continue;
    const rets = []; let bare = false;
    (function w(n, top) {
      if (!n || typeof n.type !== 'string') return;
      if (!top && isFn(n)) return;
      if (n.type === 'ReturnStatement') { if (n.argument) rets.push(n.argument); else bare = true; }
      for (const k in n) { if (k === 'loc' || k[0] === '_') continue; const v = n[k]; if (Array.isArray(v)) v.forEach(c => w(c)); else if (v && typeof v.type === 'string') w(v); }
    })(g.node, true);
    if (!rets.length || bare) { g.retType = null; continue; }
    const ts = rets.map(inferType);
    g.retType = ts.every(t => t === ts[0]) ? ts[0] : null;
  }
}

// ───────────────────────────── emitter ─────────────────────────────
class Emitter {
  constructor(mod) { this.mod = mod; this.pre = []; this.tmp = 0; this.hoisted = []; this.pathStack = []; this.cidx = 0; this.loopStack = []; this.fnStack = []; this.inTopData = false; }
  warn(n, m) { warn(this.mod, n, m); }
  newTmp(p = '_t') { return p + (++this.tmp); }

  // ── names ──
  globalRef(name, node) {
    const g = lookupGlobal(name, this.mod);
    if (!g) return null;
    const gn = safeGlobal(name);
    return g.mod === this.mod ? gn : g.mod.name + '.' + gn;
  }
  bindName(b) {
    if (!b.gd) {
      let base = safeLocal(b.name);
      // avoid shadowing an enclosing local inside the same top-level function
      let n = base, i = 1;
      const clash = nm => {
        for (let s = b.scope; s; s = s.parent) {
          if (s.leaked && s.leaked.has(nm)) return true;
          if (s !== b.scope) for (const o of s.b.values()) if (o !== b && o.gd === nm) return true;
        }
        return false;
      };
      while (clash(n)) n = base + '_' + (++i);
      b.gd = n;
    }
    return b.gd;
  }
  ident(node) {
    const b = node._b;
    if (b) { const n = this.bindName(b); return b.boxed ? n + '[0]' : n; }
    const name = node.name;
    if (name === 'undefined') return 'null';
    if (name === 'NaN') return 'NAN';
    if (name === 'Infinity') return 'INF';
    const g = this.globalRef(name, node);
    if (g) return g;
    switch (name) {
      case 'document': return 'document';
      case 'window': case 'globalThis': return 'window';
      case 'localStorage': return 'localStorage';
      case 'navigator': return 'window.navigator';
      case 'console': return 'JS.console';
      case 'requestAnimationFrame': case 'cancelAnimationFrame': case 'setTimeout': case 'clearTimeout': case 'setInterval': case 'clearInterval':
      case 'parseInt': case 'parseFloat': case 'isNaN': case 'confirm': case 'alert': return 'JS.' + name;
      case 'innerWidth': case 'innerHeight': return 'window.' + name;
      case 'Boolean': return 'JS.t';
      case 'String': return 'JS.s';
      case 'Number': return 'JS.num';
    }
    if (name.startsWith('JS_')) return 'JS.' + name.slice(3);
    if (WINDOW_PROPS.has(name)) return `window.get(${strLit(name)})`;
    this.warn(node, `unknown identifier ${name}`);
    return `JS.undef(${strLit(name)})`;
  }

  // ── conditions ──
  isBool(n) { return inferType(n) === 'bool'; }
  cond(n) {
    if (n.type === 'LogicalExpression' && n.operator !== '??') return `(${this.cond(n.left)} ${n.operator === '&&' ? 'and' : 'or'} ${this.cond(n.right)})`;
    if (n.type === 'UnaryExpression' && n.operator === '!') return `not ${this.condP(n.argument)}`;
    const k = this.constTruth(n);
    if (k !== null) return k ? 'true' : 'false';
    if (this.isBool(n)) return this.expr(n);
    return `JS.t(${this.safe(n)})`;
  }
  condP(n) { const c = this.cond(n); return /^[\w.]+(\(.*\))?$/.test(c) || c.startsWith('(') || c.startsWith('JS.t(') ? c : `(${c})`; }
  // typeof X === 'function' on known globals etc. → constant
  constTruth(n) {
    if (n.type === 'Literal' && typeof n.value === 'boolean') return n.value;
    if (n.type === 'BinaryExpression' && /^[!=]==?$/.test(n.operator)) {
      let t = null, lit = null;
      if (n.left.type === 'UnaryExpression' && n.left.operator === 'typeof' && n.right.type === 'Literal') { t = n.left.argument; lit = n.right.value; }
      else if (n.right.type === 'UnaryExpression' && n.right.operator === 'typeof' && n.left.type === 'Literal') { t = n.right.argument; lit = n.left.value; }
      if (t && t.type === 'Identifier' && !t._b) {
        const g = lookupGlobal(t.name, this.mod);
        let actual;
        if (g) actual = g.kind === 'func' || g.isFn ? 'function' : null;
        else if (['document', 'window', 'localStorage', 'navigator'].includes(t.name)) actual = 'object';
        else if (['requestAnimationFrame', 'setTimeout'].includes(t.name)) actual = 'function';
        else actual = 'undefined';
        if (actual === null) { // a global variable: only the 'undefined' comparison is decidable
          if (lit === 'undefined') return n.operator[0] === '!';
          return null;
        }
        const eq = actual === lit;
        return n.operator[0] === '!' ? !eq : eq;
      }
      if (t && t.type === 'MemberExpression' && t.object.type === 'Identifier' && t.object.name === 'window' && !t.computed) {
        const g = GLOBALS.get(t.property.name);
        if (g && (g.kind === 'func' || g.isFn)) { const eq = lit === 'function'; return n.operator[0] === '!' ? !eq : eq; }
      }
    }
    if (n.type === 'LogicalExpression' && n.operator === '&&') { const a = this.constTruth(n.left), b = this.constTruth(n.right); if (a === false || b === false) return false; if (a === true && b === true) return true; }
    if (n.type === 'LogicalExpression' && n.operator === '||') { const a = this.constTruth(n.left), b = this.constTruth(n.right); if (a === true || b === true) return true; if (a === false && b === false) return false; }
    if (n.type === 'UnaryExpression' && n.operator === '!') { const a = this.constTruth(n.argument); if (a !== null) return !a; }
    return null;
  }
  // strip constant-true typeof guards out of && chains
  simplifyCond(n) {
    if (n.type === 'LogicalExpression' && n.operator === '&&') {
      if (this.constTruth(n.left) === true) return this.simplifyCond(n.right);
      if (this.constTruth(n.right) === true) return this.simplifyCond(n.left);
    }
    return n;
  }
  // member read that tolerates a missing key
  safe(n) {
    if (n.type === 'ChainExpression') return this.expr(n);
    if (n.type === 'MemberExpression' && n.object.type !== 'Super') {
      const special = this.memberSpecial(n);
      if (special) return special;
      const o = this.exprP(n.object);
      if (n.computed) return `JS.idx(${this.expr(n.object)}, ${this.expr(n.property)})`;
      return `${o}.get(${strLit(n.property.name)})`;
    }
    return this.expr(n);
  }

  // ── expressions ──
  exprP(n) { // parenthesise when used as operand / member base
    const s = this.expr(n);
    switch (n.type) {
      case 'Identifier': case 'Literal': case 'MemberExpression': case 'CallExpression': case 'ArrayExpression': case 'ObjectExpression': case 'ThisExpression': case 'TemplateLiteral': case 'NewExpression':
        if (n.type === 'Literal' && typeof n.value === 'number' && n.value < 0) return `(${s})`;
        if (n.type === 'TemplateLiteral' && n.expressions.length) return `(${s})`;
        return s;
    }
    if (/^\(.*\)$/.test(s) && balanced(s.slice(1, -1))) return s;
    return `(${s})`;
  }
  str(n) { // expression coerced to string
    if (inferType(n) === 'string') return this.expr(n);
    return `JS.s(${this.expr(n)})`;
  }
  expr(n) {
    switch (n.type) {
      case 'Literal':
        if (n.regex) return `JS.re(${strLit(n.regex.pattern)}, ${strLit(n.regex.flags)})`;
        if (n.value === null) return 'null';
        if (typeof n.value === 'string') return strLit(n.value);
        if (typeof n.value === 'number') return numLit(n.value, n.raw);
        return String(n.value);
      case 'TemplateLiteral': {
        const parts = [];
        n.quasis.forEach((q, i) => {
          if (q.value.cooked) parts.push(strLit(q.value.cooked));
          if (i < n.expressions.length) parts.push(this.strOperand(n.expressions[i]));
        });
        if (!parts.length) return '""';
        if (parts.length === 1 && !parts[0].startsWith('"')) return parts[0];
        return parts.join(' + ');
      }
      case 'Identifier': return this.ident(n);
      case 'ThisExpression': this.fnStack.length && (this.fnStack[this.fnStack.length - 1].usesThis = true); this.usesThis = true; return 'this';
      case 'ArrayExpression': return this.arrayLit(n);
      case 'ObjectExpression': return this.objectLit(n);
      case 'FunctionExpression': case 'ArrowFunctionExpression': return this.lambda(n);
      case 'UnaryExpression': return this.unary(n);
      case 'UpdateExpression': return this.updateExpr(n);
      case 'BinaryExpression': return this.binary(n);
      case 'LogicalExpression': return this.logical(n);
      case 'ConditionalExpression': {
        const k = this.constTruth(n.test);
        if (k === true) return this.expr(n.consequent);
        if (k === false) return this.expr(n.alternate);
        return `(${this.expr(n.consequent)} if ${this.cond(n.test)} else ${this.expr(n.alternate)})`;
      }
      case 'AssignmentExpression': return this.assignExpr(n);
      case 'MemberExpression': return this.member(n);
      case 'CallExpression': return this.call(n);
      case 'NewExpression': return this.newExpr(n);
      case 'SequenceExpression': {
        for (let i = 0; i < n.expressions.length - 1; i++) this.pre.push(...this.exprStmt(n.expressions[i]));
        return this.expr(n.expressions[n.expressions.length - 1]);
      }
      case 'SpreadElement': this.warn(n, 'bare spread'); return this.expr(n.argument);
      case 'ChainExpression': return this.chain(n.expression);
      case 'ParenthesizedExpression': return this.expr(n.expression);
    }
    this.warn(n, 'unsupported expr ' + n.type);
    return `null # ${n.type}`;
  }
  strOperand(n) { const s = this.str(n); return (n.type === 'ConditionalExpression' || n.type === 'BinaryExpression' || n.type === 'LogicalExpression') && !s.startsWith('JS.s(') && !s.startsWith('(') ? `(${s})` : s; }
  chain(n) {
    // a?.b, a?.[i], a?.b(), a?.b.c
    if (n.type === 'MemberExpression') {
      const o = n.object.type === 'MemberExpression' || n.object.type === 'CallExpression' ? this.chain(n.object) : this.expr(n.object);
      if (n.computed) return `JS.idx(${o}, ${this.expr(n.property)})`;
      if (n.property.name === 'length') return `JS.len(${o})`;
      return `JS.g(${o}, ${strLit(n.property.name)})`;
    }
    if (n.type === 'CallExpression') {
      if (n.callee.type === 'MemberExpression' && !n.callee.computed) {
        const o = n.callee.object.type === 'MemberExpression' || n.callee.object.type === 'CallExpression' ? this.chain(n.callee.object) : this.expr(n.callee.object);
        return `JS.callm_opt(${o}, ${strLit(n.callee.property.name)}, [${n.arguments.map(a => this.expr(a)).join(', ')}])`;
      }
    }
    return this.expr(n);
  }
  arrayLit(n) {
    if (n.elements.some(e => e && e.type === 'SpreadElement')) {
      if (n.elements.length === 1) return `JS.arr(${this.expr(n.elements[0].argument)})`;
      const parts = []; let cur = [];
      for (const e of n.elements) {
        if (e.type === 'SpreadElement') { if (cur.length) { parts.push('[' + cur.join(', ') + ']'); cur = []; } parts.push(`JS.arr(${this.expr(e.argument)})`); }
        else cur.push(this.expr(e));
      }
      if (cur.length) parts.push('[' + cur.join(', ') + ']');
      return parts.join(' + ');
    }
    const els = n.elements.map((e, i) => { if (!e) return 'null'; this.pathStack.push(this.elemKey(e, i)); const s = this.expr(e); this.pathStack.pop(); return s; });
    const one = '[' + els.join(', ') + ']';
    if (one.length <= 100 && !one.includes('\n')) return one;
    return '[\n' + els.map(e => ind(e)).join(',\n') + ',\n]';
  }
  elemKey(e, i) {
    if (e.type === 'ObjectExpression') { const idp = e.properties.find(p => p.type === 'Property' && !p.computed && (p.key.name === 'id' || p.key.value === 'id') && p.value.type === 'Literal'); if (idp) return String(idp.value.value); }
    return String(i);
  }
  propKey(p) { return p.key.type === 'Identifier' && !p.computed ? p.key.name : p.key.type === 'Literal' ? String(p.key.value) : null; }
  objectLit(n) {
    const hasSpread = n.properties.some(p => p.type === 'SpreadElement');
    const groups = []; let cur = [];
    for (const p of n.properties) {
      if (p.type === 'SpreadElement') { if (cur.length) { groups.push(this.dictText(cur)); cur = []; } groups.push(this.expr(p.argument)); continue; }
      let key;
      if (p.computed) key = this.expr(p.key); else key = strLit(this.propKey(p));
      let val;
      if (p.kind === 'get' || p.kind === 'set') { this.warn(p, 'accessor property ' + this.propKey(p)); val = 'null'; }
      else {
        this.pathStack.push(p.computed ? 'c' : this.propKey(p));
        if (p.method || p.value.type === 'FunctionExpression') val = this.lambda(p.value, true);
        else val = this.expr(p.value);
        this.pathStack.pop();
      }
      cur.push(`${key}: ${val}`);
    }
    if (!hasSpread) return this.dictText(cur);
    if (cur.length) groups.push(this.dictText(cur));
    return `JS.merge([${groups.join(', ')}])`;
  }
  dictText(items) {
    const one = '{' + items.join(', ') + '}';
    if (one.length <= 110 && !one.includes('\n')) return one;
    return '{\n' + items.map(e => ind(e)).join(',\n') + ',\n}';
  }
  unary(n) {
    const a = n.argument;
    switch (n.operator) {
      case '!': { const k = this.constTruth(n); if (k !== null) return k ? 'true' : 'false'; return `(not ${this.condP(a)})`; }
      case '-': return a.type === 'Literal' ? '-' + this.expr(a) : `-${this.exprP(a)}`;
      case '+': return inferType(a) === 'number' ? this.expr(a) : `JS.num(${this.expr(a)})`;
      case '~': return `~${this.exprP(a)}`;
      case 'typeof': return `JS.typeof_(${this.safe(a)})`;
      case 'void': return 'null';
      case 'delete':
        if (a.type === 'MemberExpression') return `JS.del(${this.expr(a.object)}, ${a.computed ? this.expr(a.property) : strLit(a.property.name)})`;
    }
    this.warn(n, 'unary ' + n.operator); return 'null';
  }
  updateExpr(n) { // value context: hoist
    const t = this.lvalue(n.argument);
    const op = n.operator === '++' ? '+= 1' : '-= 1';
    if (n.prefix) { this.pre.push(`${t} ${op}`); return t; }
    const tmp = this.newTmp();
    this.pre.push(`var ${tmp} = ${t}`, `${t} ${op}`);
    return tmp;
  }
  binary(n) {
    const op = n.operator; const L = n.left, R = n.right;
    const k = this.constTruth(n);
    if (k !== null) return k ? 'true' : 'false';
    switch (op) {
      case '+': {
        const ls = isStringy(L), rs = isStringy(R);
        if (inferType(n) === 'string' || ls || rs) {
          const parts = []; const flat = (x) => { if (x.type === 'BinaryExpression' && x.operator === '+' && (inferType(x) === 'string' || isStringy(x.left) || isStringy(x.right))) { flat(x.left); flat(x.right); } else parts.push(x); };
          flat(n);
          // a sub-sum of unknown types inside a string chain may itself be a concatenation
          const amb = (p) => p.type === 'BinaryExpression' && p.operator === '+' && inferType(p) == null;
          const addExpr = (p) => amb(p) ? `JS.add(${addExpr(p.left)}, ${addExpr(p.right)})` : this.expr(p);
          return parts.map(p => inferType(p) === 'string' ? this.exprP(p) : (amb(p) ? `JS.s(${addExpr(p)})` : this.strOperand(p))).join(' + ');
        }
        return `${this.num(L)} + ${this.num(R)}`;
      }
      case '-': case '*': return `${this.num(L)} ${op} ${this.num(R)}`;
      case '/':
        if (R.type === 'Literal' && typeof R.value === 'number') { const t = numLit(R.value, null); return `${this.num(L)} / ${t.includes('.') || /e/i.test(t) ? t : t + '.0'}`; }
        return `${this.num(L)} / float(${this.num(R)})`;
      case '%': return `JS.mod(${this.expr(L)}, ${this.expr(R)})`;
      case '**': return `pow(${this.expr(L)}, ${this.expr(R)})`;
      case '===': case '==': case '!==': case '!=': {
        const o = op[0] === '!' ? '!=' : '==';
        const isNullish = x => (x.type === 'Literal' && x.value === null) || (x.type === 'Identifier' && x.name === 'undefined' && !x._b);
        if (isNullish(R)) return `${this.safeP(L)} ${o} null`;
        if (isNullish(L)) return `${this.safeP(R)} ${o} null`;
        if (L.type === 'UnaryExpression' && L.operator === 'typeof' || R.type === 'UnaryExpression' && R.operator === 'typeof') return `${this.exprP(L)} ${o} ${this.exprP(R)}`;
        const lt = inferType(L), rt = inferType(R);
        if (lt && rt && lt !== rt) return `JS.eq(${this.expr(L)}, ${this.expr(R)})` + (o === '!=' ? ' == false' : '');
        // comparing something possibly-missing against a literal
        const a = (R.type === 'Literal' && L.type === 'MemberExpression') ? this.safeP(L) : this.exprP(L);
        const b = (L.type === 'Literal' && R.type === 'MemberExpression') ? this.safeP(R) : this.exprP(R);
        if (rt === 'bool' && lt == null || lt === 'bool' && rt == null) return (o === '!=' ? 'not ' : '') + `JS.eq(${a}, ${b})`;
        if (rt === 'number' && lt == null && R.type === 'Literal') return (o === '!=' ? 'not ' : '') + `JS.eq(${a}, ${b})`;
        if (lt == null && rt == null && L.type !== 'Literal' && R.type !== 'Literal') return (o === '!=' ? 'not ' : '') + `JS.eq(${this.expr(L)}, ${this.expr(R)})`;
        return `${a} ${o} ${b}`;
      }
      case '<': case '>': case '<=': case '>=': return `${this.num(L)} ${op} ${this.num(R)}`;
      case '&': case '|': case '^': case '<<': case '>>':
        if (op === '|' && R.type === 'Literal' && R.value === 0) return `int(${this.expr(L)})`;
        return `${this.exprP(L)} ${op} ${this.exprP(R)}`;
      case '>>>': return `JS.ushr(${this.expr(L)}, ${this.expr(R)})`;
      case 'in': return `JS.has(${this.expr(R)}, ${this.expr(L)})`;
      case 'instanceof': return `JS.instanceof_(${this.expr(L)}, ${strLit(R.name || '?')})`;
    }
    this.warn(n, 'binary ' + op); return 'null';
  }
  safeP(n) { const s = this.safe(n); return n.type === 'MemberExpression' || n.type === 'Identifier' || n.type === 'CallExpression' || n.type === 'Literal' || n.type === 'ThisExpression' || n.type === 'ChainExpression' ? s : `(${s})`; }
  // run fn collecting its pre-statements separately; returns [text, pre]
  isolated(fn) { const save = this.pre; this.pre = []; const s = fn(); const p = this.pre; this.pre = save; return [s, p]; }
  lazy(n) { // expression wrapped in a lambda for lazy evaluation
    const [s, p] = this.isolated(() => this.expr(n));
    if (!p.length) return `func(): return ${s}`;
    const name = this.newTmp('_lz');
    this.pre.push(`var ${name} = func():\n${ind([...p, 'return ' + s].join('\n'))}`);
    return name;
  }
  logical(n) {
    const op = n.operator, L = n.left, R = n.right;
    const k = this.constTruth(n);
    if (k !== null && inferType(n) === 'bool') return k ? 'true' : 'false';
    if (op === '&&' && this.constTruth(L) === true) return this.expr(R);
    if (op === '&&' && this.constTruth(L) === false) return 'false';
    if (op === '||' && this.constTruth(L) === false) return this.expr(R);
    if (op !== '??' && this.isBool(L) && this.isBool(R)) return `(${this.cond(L)} ${op === '&&' ? 'and' : 'or'} ${this.cond(R)})`;
    if (op === '||') {
      if (isSimple(R)) return `JS.or_(${this.safe(L)}, ${this.safe(R)})`;
      if (isSimple(L)) { const [r, p] = this.isolated(() => this.expr(R)); if (!p.length) { const l = this.safe(L); return `(${l} if JS.t(${l}) else ${r})`; } }
      return `JS.orf(${this.safe(L)}, ${this.lazy(R)})`;
    }
    if (op === '&&') {
      if (isSimple(L)) { const [r, p] = this.isolated(() => this.safe(R)); if (!p.length) { const l = this.safe(L); return `(${r} if JS.t(${l}) else ${l})`; } }
      return `JS.andf(${this.safe(L)}, ${this.lazy(R)})`;
    }
    // ??
    if (isSimple(R)) return `JS.nn(${this.safe(L)}, ${this.expr(R)})`;
    return `JS.nnf(${this.safe(L)}, ${this.lazy(R)})`;
  }
  lvalue(n) {
    if (n.type === 'Identifier') {
      const b = n._b;
      if (b) return this.ident(n);
      const g = this.globalRef(n.name, n);
      if (g) return g;
      WINDOW_PROPS.add(n.name);
      return `window.${safeLocal(n.name)}`;
    }
    if (n.type === 'MemberExpression') {
      if (n.object.type === 'Identifier' && n.object.name === 'window' && !n.object._b && !n.computed) {
        const g = this.globalRef(n.property.name, n); if (g) return g;
        WINDOW_PROPS.add(n.property.name);
      }
      const o = this.exprP(n.object);
      if (n.computed) return `${o}[${this.expr(n.property)}]`;
      const p = n.property.name;
      if (PROP_KEYWORDS.has(p)) return `${o}[${strLit(p)}]`;
      return `${o}.${p}`;
    }
    this.warn(n, 'lvalue ' + n.type); return '_';
  }
  assignStmt(n) { // returns array of statement lines
    const op = n.operator, L = n.left, R = n.right;
    if (L.type === 'ArrayPattern' || L.type === 'ObjectPattern') return this.destructure(L, R, false);
    if (L.type === 'MemberExpression' && !L.computed && L.property.name === 'length') {
      const o = this.expr(L.object);
      if (R.type === 'Literal' && R.value === 0) return [`${o}.clear()`];
      return [`${o}.resize(${this.expr(R)})`];
    }
    if (op === '=' && R.type === 'AssignmentExpression' && R.operator === '=') { // a = b = c
      const inner = this.assignStmt(R);
      return [...inner, `${this.lvalue(L)} = ${this.lvalue(R.left)}`];
    }
    const t = this.lvalue(L);
    const boxedFn = L.type === 'Identifier' && L._b && L._b.boxed;
    switch (op) {
      case '=': {
        this.pathStack.push(L.type === 'Identifier' ? L.name : (L.type === 'MemberExpression' && !L.computed ? L.property.name : 'x'));
        const v = this.expr(R); this.pathStack.pop();
        // element.style = "..." / el.onclick = fn etc. are handled by the runtime setters
        return [`${t} = ${v}`];
      }
      case '+=':
        if (isStringy(L) || isStringy(R)) return [`${t} += ${this.str(R)}`];
        return [`${t} += ${this.expr(R)}`];
      case '-=': case '*=': return [`${t} ${op} ${this.expr(R)}`];
      case '/=': return [`${t} = ${t} / float(${this.expr(R)})`];
      case '%=': return [`${t} = JS.mod(${t}, ${this.expr(R)})`];
      case '**=': return [`${t} = pow(${t}, ${this.expr(R)})`];
      case '|=': case '&=': case '^=': case '<<=': case '>>=': return [`${t} ${op} ${this.expr(R)}`];
      case '||=': return [`if not JS.t(${this.safe(L)}):\n${T}${t} = ${this.expr(R)}`];
      case '&&=': return [`if JS.t(${this.safe(L)}):\n${T}${t} = ${this.expr(R)}`];
      case '??=': return [`if ${this.safe(L)} == null:\n${T}${t} = ${this.expr(R)}`];
    }
    this.warn(n, 'assign op ' + op); return [];
  }
  assignExpr(n) { // assignment used as a value
    const stmts = this.assignStmt(n);
    this.pre.push(...stmts);
    return this.lvalue(n.left.type === 'ArrayPattern' || n.left.type === 'ObjectPattern' ? n.right : n.left);
  }
  destructure(pat, init, declare, initText) {
    const out = [];
    let src = initText;
    if (src == null) {
      if (pat.type === 'ArrayPattern' && init.type === 'ArrayExpression' && init.elements.length === pat.elements.length && !declare) {
        // [a, b] = [b, a]  → temps
        const tmps = init.elements.map(e => { const t = this.newTmp(); out.push(`var ${t} = ${this.expr(e)}`); return t; });
        pat.elements.forEach((e, i) => { if (e) out.push(`${this.lvalue(e)} = ${tmps[i]}`); });
        return out;
      }
      if (init.type === 'Identifier') src = this.expr(init);
      else { src = this.newTmp('_d'); out.push(`var ${src} = ${this.expr(init)}`); }
    }
    const bindTo = (target, valueText) => {
      if (!target) return;
      if (target.type === 'AssignmentPattern') {
        const t2 = this.newTmp('_d'); out.push(`var ${t2} = ${valueText}`);
        out.push(`if ${t2} == null:\n${T}${t2} = ${this.expr(target.right)}`);
        bindTo(target.left, t2); return;
      }
      if (target.type === 'Identifier') {
        if (declare) out.push(...this.declLines(target, valueText));
        else out.push(`${this.lvalue(target)} = ${valueText}`);
        return;
      }
      if (target.type === 'MemberExpression') { out.push(`${this.lvalue(target)} = ${valueText}`); return; }
      const t2 = this.newTmp('_d'); out.push(`var ${t2} = ${valueText}`);
      out.push(...this.destructure(target, null, declare, t2));
    };
    if (pat.type === 'ArrayPattern') pat.elements.forEach((e, i) => { if (!e) return; if (e.type === 'RestElement') bindTo(e.argument, `${src}.slice(${i})`); else bindTo(e, `JS.idx(${src}, ${i})`); });
    else pat.properties.forEach(p => {
      if (p.type === 'RestElement') { this.warn(p, 'object rest'); return; }
      const key = p.computed ? this.expr(p.key) : strLit(this.propKey(p));
      bindTo(p.value, `JS.idx(${src}, ${key})`);
    });
    return out;
  }
  // declaration of a local binding with given initializer text
  declLines(idNode, valueText) {
    const b = idNode._b;
    if (!b) { // module-level variable
      const g = this.globalRef(idNode.name, idNode);
      return valueText == null ? [] : [`${g} = ${valueText}`];
    }
    const nm = this.bindName(b);
    if (b.boxed) return valueText == null ? [] : [`${nm}[0] = ${valueText}`];
    if (b.declared) return valueText == null ? [] : [`${nm} = ${valueText}`];
    if (b.hoist && b.kind === 'var') return valueText == null ? [] : [`${nm} = ${valueText}`];
    b.declared = true;
    return [valueText == null ? `var ${nm} = null` : `var ${nm} = ${valueText}`];
  }
  memberSpecial(n) {
    // Returns text for members that need translation, or null
    const o = n.object;
    if (n.computed) return null;
    const p = n.property.name;
    if (o.type === 'Identifier' && !o._b) {
      if (o.name === 'Math') {
        const c = { PI: 'PI', E: '2.718281828459045', SQRT2: 'sqrt(2.0)', LN2: 'log(2.0)', LN10: 'log(10.0)', SQRT1_2: 'sqrt(0.5)' }[p];
        if (c) return c;
      }
      if (o.name === 'Number') { const c = { MAX_SAFE_INTEGER: '9007199254740991', EPSILON: '2.220446049250313e-16', MAX_VALUE: '1.7976931348623157e308', POSITIVE_INFINITY: 'INF', NEGATIVE_INFINITY: '-INF' }[p]; if (c) return c; }
      if (o.name === 'window') {
        const g = this.globalRef(p, n);
        if (g) return g;
        if (['innerWidth', 'innerHeight', 'devicePixelRatio', 'navigator', 'location', 'scrollY', 'scrollX'].includes(p)) return `window.${p}`;
        WINDOW_PROPS.add(p);
        return `window.get(${strLit(p)})`;
      }
    }
    if (p === 'length') return `len(${this.expr(o)})`;
    return null;
  }
  member(n) {
    const sp = this.memberSpecial(n);
    if (sp) return sp;
    const o = this.exprP(n.object);
    if (n.computed) {
      const pr = n.property;
      if (pr.type === 'Identifier' && pr._b && pr._b.loopVar && !pr._b.boxed) return `${o}[${this.expr(pr)}]`;
      return `JS.idx(${this.expr(n.object)}, ${this.expr(pr)})`;
    }
    const p = n.property.name;
    if (n.object.type === 'Identifier' && !n.object._b && ['document', 'window', 'localStorage'].includes(n.object.name)) return `${o}.${p}`;
    if (!SHIM_PROPS.has(p)) return `${o}.get(${strLit(p)})`;
    if (PROP_KEYWORDS.has(p)) return `${o}[${strLit(p)}]`;
    return `${o}.${p}`;
  }
  // operand of arithmetic / relational operators: a possibly-missing read becomes NaN, as in JS
  num(n) {
    const s = this.exprP(n);
    if (n.type === 'MemberExpression' && !this.memberSpecial(n)) {
      if (n.computed) { if (!(n.property.type === 'Identifier' && n.property._b && n.property._b.loopVar && !n.property._b.boxed)) return `JS.un(${this.expr(n)})`; }
      else if (missingProne(n.property.name) && !(n.object.type === 'Identifier' && !n.object._b && ['document', 'window'].includes(n.object.name))) return `JS.un(${this.expr(n)})`;
    }
    return s;
  }
  args(list, max) {
    let a = list;
    if (max != null && a.length > max) a = a.slice(0, max);
    return a.map(x => this.expr(x)).join(', ');
  }
  // inline arrow/function used as a callback: returns {params, bodyExpr|null, node}
  call(n) {
    const c = n.callee, A = n.arguments;
    const hasSpread = A.some(a => a.type === 'SpreadElement');
    // IIFE
    if (isFn(c)) { const f = this.lambda(c); return `${this.wrapLambda(f)}.call(${this.args(A)})`; }
    if (c.type === 'Identifier') {
      const name = c.name;
      if (c._b) { // local callable
        if (hasSpread) return `${this.ident(c)}.callv(${this.spreadArgs(A)})`;
        return `${this.ident(c)}.call(${this.args(A)})`;
      }
      const g = lookupGlobal(name, this.mod);
      if (g) {
        const ref = this.globalRef(name, c);
        if (g.kind === 'func') {
          if (hasSpread) return `${ref}.callv(${this.spreadArgs(A)})`;
          return `${ref}(${this.args(A, g.node.params.length)})`;
        }
        if (hasSpread) return `${ref}.callv(${this.spreadArgs(A)})`;
        return `${ref}.call(${this.args(A)})`;
      }
      switch (name) {
        case 'parseInt': return `JS.parseInt(${this.args(A)})`;
        case 'parseFloat': return `JS.parseFloat(${this.args(A)})`;
        case 'Number': return `JS.num(${this.args(A)})`;
        case 'String': return `JS.s(${this.args(A)})`;
        case 'Boolean': return `JS.t(${this.args(A)})`;
        case 'isNaN': return `JS.isNaN(${this.args(A)})`;
        case 'isFinite': return `JS.isFinite(${this.args(A)})`;
        case 'Array': return `JS.newArray(${this.args(A)})`;
        case 'setTimeout': case 'setInterval': return `JS.${name}(${this.args(A, 2)})`;
        case 'clearTimeout': case 'clearInterval': case 'requestAnimationFrame': case 'cancelAnimationFrame': case 'alert': case 'confirm':
          return `JS.${name}(${this.args(A)})`;
        case 'gtag': return `JS.gtag([${this.args(A)}])`;
      }
      if (name.startsWith('JS_')) return `JS.${name.slice(3)}(${this.args(A)})`;
      switch (name) {
      }
      this.warn(n, `call to unknown function ${name}`);
      return `JS.undef_call(${strLit(name)}, [${this.args(A)}])`;
    }
    if (c.type === 'MemberExpression') return this.methodCall(n);
    return `${this.exprP(c)}.call(${this.args(A)})`;
  }
  spreadArgs(A) {
    const parts = []; let cur = [];
    for (const a of A) { if (a.type === 'SpreadElement') { if (cur.length) { parts.push('[' + cur.join(', ') + ']'); cur = []; } parts.push(`JS.arr(${this.expr(a.argument)})`); } else cur.push(this.expr(a)); }
    if (cur.length) parts.push('[' + cur.join(', ') + ']');
    return parts.join(' + ');
  }
  // callback helpers
  cbInfo(a) { return isFn(a) ? { n: a.params.length } : null; }
  methodCall(n) {
    const c = n.callee, A = n.arguments, O = c.object;
    if (c.computed) { // obj[expr](args)
      return `JS.callm(${this.expr(O)}, ${this.expr(c.property)}, [${this.args(A)}])`;
    }
    const m = c.property.name;
    const a = (i) => this.expr(A[i]);
    const all = () => this.args(A);
    // ── static objects ──
    if (O.type === 'Identifier' && !O._b && !lookupGlobal(O.name, this.mod)) {
      switch (O.name) {
        case 'Math': return this.mathCall(m, n);
        case 'Object':
          switch (m) {
            case 'keys': return `JS.keys(${a(0)})`;
            case 'values': return `JS.values(${a(0)})`;
            case 'entries': return `JS.entries(${a(0)})`;
            case 'assign': return `JS.assign(${a(0)}, [${A.slice(1).map(x => this.expr(x)).join(', ')}])`;
            case 'freeze': return a(0);
            case 'fromEntries': return `JS.fromEntries(${a(0)})`;
          }
          break;
        case 'Array':
          if (m === 'isArray') return `(${a(0)} is Array)`;
          if (m === 'from') return A.length > 1 ? `JS.arrayFrom(${a(0)}, ${a(1)})` : `JS.arr(${a(0)})`;
          break;
        case 'JSON':
          if (m === 'parse') return `JS.jsonParse(${a(0)})`;
          if (m === 'stringify') return `JS.jsonStringify(${a(0)})`;
          break;
        case 'Number':
          if (m === 'isInteger') return `JS.isInteger(${a(0)})`;
          if (m === 'isFinite') return `JS.isFinite(${a(0)})`;
          if (m === 'parseFloat') return `JS.parseFloat(${a(0)})`;
          break;
        case 'Date': if (m === 'now') return 'JS.dateNow()'; break;
        case 'performance': if (m === 'now') return 'JS.now()'; break;
        case 'console': return `JS.console_${m}([${all()}])`;
        case 'String': if (m === 'fromCharCode') return `char(${a(0)})`; break;
        case 'window':
          if (GLOBALS.has(m)) { const g = GLOBALS.get(m); return g.kind === 'func' ? `${this.globalRef(m)}(${this.args(A, g.node.params.length)})` : `${this.globalRef(m)}.call(${all()})`; }
          if (['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout', 'confirm', 'alert'].includes(m)) return `JS.${m}(${all()})`;
          if (['addEventListener', 'removeEventListener', 'getComputedStyle', 'matchMedia', 'scrollTo', 'open'].includes(m)) return `window.${m}(${all()})`;
          return `JS.callm(window, ${strLit(m)}, [${all()}])`;
      }
    }
    let _oe = null; const oe = () => (_oe === null ? (_oe = this.expr(O)) : _oe);
    const needP = !['Identifier','Literal','MemberExpression','CallExpression','ArrayExpression','ObjectExpression','ThisExpression','NewExpression'].includes(O.type) || (O.type === 'Literal' && typeof O.value === 'number');
    const o = () => needP ? `(${oe()})` : oe();
    const fnArg = A[0] && isFn(A[0]) ? A[0] : null;
    switch (m) {
      // ── arrays ──
      case 'push':
        if (A.some(x => x.type === 'SpreadElement')) return `${o()}.append_array(${this.spreadArgs(A)})`;
        if (A.length === 1) return `${o()}.append(${a(0)})`;
        return `${o()}.append_array([${all()}])`;
      case 'pop': if (!A.length) return `${o()}.pop_back()`; break;
      case 'shift': if (!A.length) return `${o()}.pop_front()`; break;
      case 'unshift': if (A.length === 1) return `${o()}.push_front(${a(0)})`; break;
      case 'forEach': return `JS.forEach(${oe()}, ${this.cb(A[0])})`;
      case 'map': if (fnArg && fnArg.params.length <= 1) return `JS.arr(${oe()}).map(${this.cb(A[0], 1)})`; return `JS.map(${oe()}, ${this.cb(A[0])})`;
      case 'filter': if (fnArg && fnArg.params.length <= 1) return `JS.arr(${oe()}).filter(${this.cb(A[0], 1, true)})`; return `JS.filter(${oe()}, ${this.cb(A[0], null, true)})`;
      case 'find': return `JS.find(${oe()}, ${this.cb(A[0], null, true)})`;
      case 'findIndex': return `JS.findIndex(${oe()}, ${this.cb(A[0], null, true)})`;
      case 'some': return `JS.some(${oe()}, ${this.cb(A[0], null, true)})`;
      case 'every': return `JS.every(${oe()}, ${this.cb(A[0], null, true)})`;
      case 'reduce': return `JS.reduce(${oe()}, ${this.cb(A[0])}${A[1] ? ', ' + a(1) : ''})`;
      case 'sort': return A.length ? `JS.sort(${oe()}, ${this.cb(A[0])})` : `JS.sort(${oe()})`;
      case 'reverse': return `JS.reverse(${oe()})`;
      case 'includes': return `JS.includes(${oe()}, ${a(0)})`;
      case 'indexOf': return `JS.indexOf(${oe()}, ${all()})`;
      case 'lastIndexOf': return `${o()}.rfind(${all()})`;
      case 'join': return `JS.join(${oe()}${A.length ? ', ' + a(0) : ''})`;
      case 'slice': return `JS.slice(${oe()}${A.length ? ', ' + all() : ''})`;
      case 'splice': return `JS.splice(${oe()}, ${a(0)}${A.length > 1 ? ', ' + a(1) : ''}${A.length > 2 ? ', [' + A.slice(2).map(x => this.expr(x)).join(', ') + ']' : ''})`;
      case 'concat': return `JS.concat(${oe()}, [${all()}])`;
      case 'flat': return `JS.flat(${oe()})`;
      case 'flatMap': return `JS.flat(JS.map(${oe()}, ${this.cb(A[0])}))`;
      case 'fill': if (A.length === 1 && !(O.type === 'Identifier' && /ctx|^c$|^g$/i.test(O.name))) return `JS.fill(${oe()}, ${a(0)})`; break;
      case 'keys': if (!A.length) return `JS.keys(${oe()})`; break;
      case 'values': if (!A.length) return `JS.values(${oe()})`; break;
      case 'entries': if (!A.length) return `JS.entries(${oe()})`; break;
      // ── strings ──
      case 'toUpperCase': return `${o()}.to_upper()`;
      case 'toLowerCase': return `${o()}.to_lower()`;
      case 'trim': return `${o()}.strip_edges()`;
      case 'startsWith': return `${o()}.begins_with(${a(0)})`;
      case 'endsWith': return `${o()}.ends_with(${a(0)})`;
      case 'split': return `JS.split(${oe()}${A.length ? ', ' + all() : ''})`;
      case 'replace': case 'replaceAll': return `JS.${m}(${oe()}, ${a(0)}, ${a(1)})`;
      case 'match': return `JS.match_(${oe()}, ${a(0)})`;
      case 'test': return `JS.test(${oe()}, ${a(0)})`;
      case 'charAt': return `JS.charAt(${oe()}, ${a(0)})`;
      case 'charCodeAt': return `${o()}.unicode_at(${A.length ? a(0) : '0'})`;
      case 'substring': case 'substr': return `JS.${m}(${oe()}, ${all()})`;
      case 'padStart': case 'padEnd': return `JS.${m}(${oe()}, ${all()})`;
      case 'repeat': return `${o()}.repeat(${a(0)})`;
      case 'toFixed': return `JS.toFixed(${oe()}, ${A.length ? a(0) : '0'})`;
      case 'toString': return `JS.s(${oe()})`;
      case 'toLocaleString': return `JS.toLocaleString(${oe()})`;
      case 'toLocaleDateString': return `JS.toLocaleDateString(${oe()})`;
      case 'localeCompare': return `JS.localeCompare(${oe()}, ${a(0)})`;
      case 'hasOwnProperty': return `JS.has(${oe()}, ${a(0)})`;
      case 'call': return `${o()}.call(${A.slice(1).map(x => this.expr(x)).join(', ')})`;
      case 'bind': return o();
    }
    if (NATIVE_METHODS.has(m)) {
      if (m === 'addEventListener' || m === 'removeEventListener') return `${o()}.${m}(${this.args(A, 3)})`;
      return `${o()}.${m}(${all()})`;
    }
    // dictionary-held function (spell.execute(s), cat.aura(lvl), …)
    return `JS.callm(${oe()}, ${strLit(m)}, [${all()}])`;
  }
  mathCall(m, n) {
    const A = n.arguments; const a = i => this.expr(A[i]);
    const spread = A.length === 1 && A[0].type === 'SpreadElement';
    switch (m) {
      case 'floor': return `floori(${a(0)})`;
      case 'ceil': return `ceili(${a(0)})`;
      case 'round': return `JS.round(${a(0)})`;
      case 'trunc': return `int(${a(0)})`;
      case 'random': return 'randf()';
      case 'max': case 'min':
        if (spread) return `JS.arr${m === 'max' ? 'Max' : 'Min'}(${this.expr(A[0].argument)})`;
        if (A.length === 1) return a(0);
        if (A.some(x => x.type === 'SpreadElement')) return `JS.arr${m === 'max' ? 'Max' : 'Min'}(${this.spreadArgs(A)})`;
        return `${m}(${this.args(A)})`;
      case 'abs': case 'sqrt': case 'sin': case 'cos': case 'tan': case 'atan': case 'asin': case 'acos': case 'exp': case 'atan2': case 'pow': case 'sign':
        return `${m}(${this.args(A)})`;
      case 'log': return `log(${a(0)})`;
      case 'log2': return `(log(${a(0)}) / log(2.0))`;
      case 'log10': return `(log(${a(0)}) / log(10.0))`;
      case 'hypot': return `JS.hypot([${this.args(A)}])`;
      case 'cbrt': return `pow(${a(0)}, 1.0 / 3.0)`;
      case 'imul': return `JS.imul(${this.args(A)})`;
    }
    this.warn(n, 'Math.' + m); return 'null';
  }
  newExpr(n) {
    const c = n.callee, A = n.arguments;
    if (c.type === 'Identifier') switch (c.name) {
      case 'Set': return `JSSet.new(${A.length ? this.expr(A[0]) : ''})`;
      case 'Map': return `JSMap.new(${A.length ? this.expr(A[0]) : ''})`;
      case 'Array': return `JS.newArray(${this.args(A)})`;
      case 'Date': return `JS.newDate(${this.args(A)})`;
      case 'Audio': return `JSAudio.new(${this.args(A)})`;
      case 'Image': return `JSImage.new()`;
      case 'ResizeObserver': return `JSResizeObserver.new(${this.args(A)})`;
      case 'Error': return this.args(A) || '""';
      case 'Promise': this.warn(n, 'Promise'); return 'null';
    }
    this.warn(n, 'new ' + (c.name || '?'));
    return 'null';
  }
  // callback argument → GDScript callable text
  cb(node, maxParams, boolRet) {
    if (isFn(node)) return this.lambda(node, false, boolRet);
    return this.expr(node);
  }
  wrapLambda(s) { return s.includes('\n') ? `(${s})` : `(${s})`; }

  // ── functions ──
  // Returns text of a lambda value. Block lambdas are hoisted into a preceding `var`.
  lambda(node, isMethod, boolRet) {
    const info = { usesThis: false, node };
    this.fnStack.push(info);
    const savePre = this.pre, saveLoop = this.loopStack; this.pre = []; this.loopStack = [];
    const { params, head } = this.params(node);
    let body;
    let single = null;
    if (node.body.type !== 'BlockStatement') {
      const e = boolRet ? this.cond(node.body) : this.expr(node.body);
      if (!this.pre.length && !head.length) single = e;
      body = [...head, ...this.pre, 'return ' + e];
    } else {
      this.pre = [];
      const stmts = this.block(node.body, head);
      body = stmts;
      // `{ return expr; }` → single-expression lambda
      if (node.body.body.length === 1 && node.body.body[0].type === 'ReturnStatement' && node.body.body[0].argument && body.length === 1 && !body[0].includes('\n')) single = body[0].replace(/^return /, '');
    }
    this.pre = savePre; this.loopStack = saveLoop;
    this.fnStack.pop();
    const usesThis = info.usesThis && node.type !== 'ArrowFunctionExpression';
    if (info.usesThis && node.type === 'ArrowFunctionExpression' && this.fnStack.length) this.fnStack[this.fnStack.length - 1].usesThis = true;
    if (usesThis) { body.unshift('var this = JS._this'); single = null; }
    if (node._selfB) { // named function expression referring to itself
      const sn = this.bindName(node._selfB), fnName = this.newTmp('_fn');
      this.pre.push(`var ${sn} = [null]`, `var ${fnName} = func(${params}):\n${ind((body.length ? body : ['pass']).join('\n'))}`, `${sn}[0] = ${fnName}`);
      return `${sn}[0]`;
    }
    // top-level data: hoist into a named module function
    if (this.inTopData && this.fnStack.length === 0 && (single === null || single.length > 90 || isMethod)) {
      const name = this.hoistName();
      this.hoisted.push(`func ${name}(${params}):\n${ind((body.length ? body : ['pass']).join('\n'))}`);
      return name;
    }
    if (single !== null && !single.includes('\n')) return `func(${params}): return ${single}`;
    const name = this.newTmp('_fn');
    this.pre.push(`var ${name} = func(${params}):\n${ind((body.length ? body : ['pass']).join('\n'))}`);
    return name;
  }
  hoistName() {
    let base = this.pathStack.map(s => String(s).replace(/[^A-Za-z0-9_]/g, '_')).join('__') || 'fn';
    if (/^[0-9]/.test(base)) base = '_' + base;
    let n = base, i = 1;
    this.usedHoist = this.usedHoist || new Set();
    while (this.usedHoist.has(n) || GLOBALS.has(n)) n = base + '_' + (++i);
    this.usedHoist.add(n);
    return n;
  }
  params(node) {
    const head = []; const ps = [];
    node.params.forEach((p, i) => {
      if (p.type === 'Identifier') { const b = p._b; const nm = this.bindName(b); ps.push(`${nm} = null`); if (b.boxed) head.push(`${nm} = [${nm}]`); b.declared = true; }
      else if (p.type === 'AssignmentPattern' && p.left.type === 'Identifier') {
        const b = p.left._b; const nm = this.bindName(b); ps.push(`${nm} = null`); b.declared = true;
        head.push(`if ${nm} == null:\n${T}${nm} = ${this.expr(p.right)}`);
        if (b.boxed) head.push(`${nm} = [${nm}]`);
      } else {
        const tmp = `_p${i}`; ps.push(`${tmp} = null`);
        const pat = p.type === 'AssignmentPattern' ? p.left : p;
        if (p.type === 'AssignmentPattern') head.push(`if ${tmp} == null:\n${T}${tmp} = ${this.expr(p.right)}`);
        head.push(...this.destructure(pat, null, true, tmp));
      }
    });
    return { params: ps.join(', '), head };
  }
  // Emit statements of a block. Returns array of statement strings (may be multi-line).
  block(node, head = []) {
    const out = [...head];
    const scope = node._scope;
    const body = node.type === 'BlockStatement' || node.type === 'Program' ? node.body : [node];
    // boxes + hoisted vars for bindings owned by this scope
    if (scope && scope.node === node || (scope && node.type === 'BlockStatement' && scope.fn && scope.fn.body === node)) {
      for (const b of scope.b.values()) {
        if (b.kind === 'param' || b.kind === 'selfname') continue;
        if (b.boxed) { out.push(`var ${this.bindName(b)} = [null]`); b.declared = true; }
        else if (b.hoist && b.kind === 'var') { out.push(`var ${this.bindName(b)} = null`); b.declared = true; }
      }
      // hoisted function declarations first
      for (const s of body) if (s.type === 'FunctionDeclaration' && s.id._b && s.id._b.hoist) out.push(...this.stmt(s, true));
    }
    for (const s of body) {
      if (s.type === 'FunctionDeclaration' && s.id._b && s.id._b.hoist) continue;
      out.push(...this.comments(s));
      out.push(...this.stmt(s));
    }
    return out;
  }
  comments(s) {
    const out = []; const cs = this.mod.comments;
    while (this.cidx < cs.length && cs[this.cidx].end <= s.start) {
      const c = cs[this.cidx++];
      if (c.start < (this.cmin || 0)) continue;
      for (const line of c.value.split('\n')) out.push('# ' + line.replace(/^\s*\*?\s?/, '').trimEnd());
    }
    return out;
  }
  skipCommentsTo(pos) { const cs = this.mod.comments; while (this.cidx < cs.length && cs[this.cidx].end <= pos) this.cidx++; }
  body(node, head) { // statement or block → indented text
    let stmts;
    if (node.type === 'BlockStatement') stmts = this.block(node, head);
    else { const savePre = this.pre; this.pre = []; stmts = [...(head || []), ...this.stmt(node)]; this.pre = savePre; }
    if (!stmts.some(s => !s.startsWith('#'))) stmts.push('pass');
    return ind(stmts.join('\n'));
  }
  // wrap: run emit fn, prepend any pre-statements it generated
  withPre(fn) {
    const save = this.pre; this.pre = [];
    const res = fn();
    const p = this.pre; this.pre = save;
    return [...p, ...(Array.isArray(res) ? res : [res])];
  }
  exprStmt(e) {
    switch (e.type) {
      case 'AssignmentExpression': return this.withPre(() => this.assignStmt(e));
      case 'UpdateExpression': return this.withPre(() => `${this.lvalue(e.argument)} ${e.operator === '++' ? '+= 1' : '-= 1'}`);
      case 'SequenceExpression': return e.expressions.flatMap(x => this.exprStmt(x));
      case 'LogicalExpression': {
        if (e.operator === '&&') { const k = this.constTruth(e.left); if (k === false) return []; if (k === true) return this.exprStmt(e.right);
          const t = this.simplifyCond(e.left);
          return this.withPre(() => `if ${this.cond(t)}:\n${ind(this.exprStmt(e.right).join('\n') || 'pass')}`); }
        if (e.operator === '||') return this.withPre(() => `if not ${this.condP(e.left)}:\n${ind(this.exprStmt(e.right).join('\n') || 'pass')}`);
        break;
      }
      case 'ConditionalExpression': {
        const k = this.constTruth(e.test);
        if (k === true) return this.exprStmt(e.consequent);
        if (k === false) return this.exprStmt(e.alternate);
        return this.withPre(() => `if ${this.cond(e.test)}:\n${ind(this.exprStmt(e.consequent).join('\n') || 'pass')}\nelse:\n${ind(this.exprStmt(e.alternate).join('\n') || 'pass')}`);
      }
      case 'CallExpression': {
        // arr.forEach(fn) → for loop
        const c = e.callee;
        if (c.type === 'MemberExpression' && !c.computed && c.property.name === 'forEach' && e.arguments.length === 1 && isFn(e.arguments[0])) {
          const r = this.forEachLoop(e); if (r) return r;
        }
        if (isFn(c) && !e.arguments.length && !c.params.length) { // IIFE statement
          return this.withPre(() => { const f = this.lambda(c); return `${f.startsWith('func') ? '(' + f + ')' : f}.call()`; });
        }
        break;
      }
      case 'UnaryExpression': if (e.operator === 'delete') return this.withPre(() => this.expr(e)); if (e.operator === 'void') return this.exprStmt(e.argument); break;
      case 'Literal': return []; // 'use strict'
      case 'Identifier': return [];
    }
    return this.withPre(() => this.expr(e));
  }
  containsOwn(node, pred, stopAtLoops) { // search without entering nested functions
    let found = false;
    (function w(n, top) {
      if (found || !n || typeof n.type !== 'string') return;
      if (!top && isFn(n)) return;
      if (pred(n)) { found = true; return; }
      if (!top && stopAtLoops && /^(For|While|DoWhile|ForIn|ForOf)Statement$/.test(n.type)) return;
      for (const k in n) { if (k === 'loc' || k[0] === '_') continue; const v = n[k]; if (Array.isArray(v)) v.forEach(c => w(c)); else if (v && typeof v.type === 'string') w(v); }
    })(node, true);
    return found;
  }
  forEachLoop(e) {
    const fn = e.arguments[0], O = e.callee.object;
    if (fn.params.length > 2) return null;
    if (fn.params.some(p => p.type !== 'Identifier' && p.type !== 'ObjectPattern' && p.type !== 'ArrayPattern')) return null;
    if (fn.params.some(p => p.type === 'Identifier' && p._b.boxed)) return null;
    // `return` inside a forEach callback behaves like `continue`
    const save = this.pre; this.pre = [];
    const seq = this.expr(O);
    const pre = this.pre; this.pre = [];
    const p0 = fn.params[0], p1 = fn.params[1];
    const head = [];
    let itemName;
    if (!p0) itemName = this.newTmp('_e');
    else if (p0.type === 'Identifier') { itemName = this.bindName(p0._b); p0._b.declared = true; }
    else { itemName = this.newTmp('_e'); head.push(...this.destructure(p0, null, true, itemName)); }
    let line;
    const seqText = `JS.iter(${seq})`;
    if (p1) {
      const idx = this.bindName(p1._b); p1._b.declared = true;
      const arrTmp = this.newTmp('_arr');
      pre.push(`var ${arrTmp} = ${seqText}`);
      line = `for ${idx} in range(len(${arrTmp})):`;
      if (!(p0 && p0.type === 'Identifier' && p0._b.refs.length === 0)) head.unshift(`var ${itemName} = ${arrTmp}[${idx}]`);
    } else line = `for ${itemName} in ${seqText}:`;
    this.loopStack.push({ type: 'forEach' });
    this.fnStack.push({ forEachBody: true, node: fn, usesThis: false });
    let bodyText;
    if (fn.body.type === 'BlockStatement') bodyText = this.body(fn.body, head);
    else { const st = this.exprStmt(fn.body); bodyText = ind([...head, ...st].join('\n') || 'pass'); }
    const info = this.fnStack.pop();
    if (info.usesThis && this.fnStack.length) this.fnStack[this.fnStack.length - 1].usesThis = true;
    this.loopStack.pop();
    this.pre = save;
    return [...pre, `${line}\n${bodyText}`];
  }
  inForEachBody() { const f = this.fnStack[this.fnStack.length - 1]; return f && f.forEachBody; }

  stmt(s, hoisting) {
    switch (s.type) {
      case 'EmptyStatement': return [];
      case 'ExpressionStatement': return this.exprStmt(s.expression);
      case 'VariableDeclaration': {
        const out = [];
        for (const d of s.declarations) {
          out.push(...this.withPre(() => {
            if (d.id.type !== 'Identifier') return this.destructure(d.id, d.init, true);
            if (!d.init) return this.declLines(d.id, null);
            this.pathStack.push(d.id.name);
            const v = this.expr(d.init);
            this.pathStack.pop();
            return this.declLines(d.id, v);
          }));
        }
        return out;
      }
      case 'FunctionDeclaration': {
        const b = s.id._b;
        const nm = this.bindName(b);
        return this.withPre(() => {
          const f = this.lambda(s);
          if (b.boxed) return `${nm}[0] = ${f}`;
          if (b.declared) return `${nm} = ${f}`;
          b.declared = true; return `var ${nm} = ${f}`;
        });
      }
      case 'ReturnStatement': {
        if (this.inForEachBody()) { // return inside forEach callback
          if (s.argument && !isSimple(s.argument)) return [...this.exprStmt(s.argument), 'continue'];
          return ['continue'];
        }
        if (!s.argument) return ['return'];
        return this.withPre(() => 'return ' + this.expr(s.argument));
      }
      case 'IfStatement': return this.ifStmt(s);
      case 'BlockStatement': { const inner = this.block(s); return inner.length ? [`if true:\n${ind(inner.join('\n'))}`] : []; }
      case 'ForStatement': return this.forStmt(s);
      case 'ForOfStatement': case 'ForInStatement': return this.forOf(s);
      case 'WhileStatement': {
        const [c, p] = this.isolated(() => this.cond(s.test));
        this.loopStack.push({ type: 'while' });
        let r;
        if (!p.length) r = [`while ${c}:\n${this.body(s.body)}`];
        else r = [`while true:\n${ind([...p, `if not (${c}):`, T + 'break'].join('\n'))}\n${this.body(s.body)}`];
        this.loopStack.pop(); return r;
      }
      case 'DoWhileStatement': {
        this.loopStack.push({ type: 'while' });
        const b = this.body(s.body);
        this.loopStack.pop();
        const [c, p] = this.isolated(() => this.cond(s.test));
        return [`while true:\n${b}\n${ind([...p, `if not (${c}):`, T + 'break'].join('\n'))}`];
      }
      case 'BreakStatement': {
        const top = this.loopStack[this.loopStack.length - 1];
        if (top && top.type === 'switch') { top.sawBreak = true; return top.loopForm ? ['break'] : ['pass  # break']; }
        return ['break'];
      }
      case 'ContinueStatement': {
        // find nearest real loop
        for (let i = this.loopStack.length - 1; i >= 0; i--) {
          const L = this.loopStack[i];
          if (L.type === 'switch') { if (L.loopForm) this.warn(s, 'continue inside loop-form switch'); continue; }
          if (L.update) return [...L.update, 'continue'];
          break;
        }
        return ['continue'];
      }
      case 'SwitchStatement': return this.switchStmt(s);
      case 'TryStatement': {
        const out = this.block(s.block);
        if (s.finalizer) out.push(...this.block(s.finalizer));
        if (s.handler) this.skipCommentsTo(s.handler.end);
        return out.length ? out : [];
      }
      case 'ThrowStatement': return this.withPre(() => [`push_error(${this.str(s.argument)})`, 'return']);
      case 'LabeledStatement': this.warn(s, 'label'); return this.stmt(s.body);
    }
    this.warn(s, 'unsupported stmt ' + s.type);
    return [`pass # ${s.type}`];
  }
  ifStmt(s) {
    const k = this.constTruth(s.test);
    if (k === true) { const r = this.stmtOrBlock(s.consequent); if (s.alternate) this.skipCommentsTo(s.alternate.end); return r; }
    if (k === false) { this.skipCommentsTo(s.consequent.end); return s.alternate ? this.stmtOrBlock(s.alternate) : []; }
    const test = this.simplifyCond(s.test);
    const [c, p] = this.isolated(() => this.cond(test));
    let text = `if ${c}:\n${this.body(s.consequent)}`;
    let alt = s.alternate;
    while (alt) {
      if (alt.type === 'IfStatement') {
        const ka = this.constTruth(alt.test);
        if (ka === true) { text += `\nelse:\n${this.body(alt.consequent)}`; if (alt.alternate) this.skipCommentsTo(alt.alternate.end); break; }
        if (ka === false) { this.skipCommentsTo(alt.consequent.end); alt = alt.alternate; continue; }
        const [c2, p2] = this.isolated(() => this.cond(this.simplifyCond(alt.test)));
        if (p2.length) { text += `\nelse:\n${ind([...p2, `if ${c2}:\n${this.body(alt.consequent)}`].join('\n'))}`; // nested form
          if (alt.alternate) text += '\n' + ind(`else:\n${this.body(alt.alternate)}`); break; }
        text += `\nelif ${c2}:\n${this.body(alt.consequent)}`;
        alt = alt.alternate;
      } else { text += `\nelse:\n${this.body(alt)}`; break; }
    }
    return [...p, text];
  }
  stmtOrBlock(n) { return n.type === 'BlockStatement' ? this.block(n) : this.stmt(n); }
  forStmt(s) {
    const out = [];
    // canonical counted loop → range()
    const init = s.init, test = s.test, upd = s.update;
    if (init && init.type === 'VariableDeclaration' && init.declarations.length === 1 && init.declarations[0].id.type === 'Identifier' && init.declarations[0].init && test && test.type === 'BinaryExpression' && upd) {
      const v = init.declarations[0].id, b = v._b;
      const isVar = x => x.type === 'Identifier' && x._b === b;
      let step = null;
      if (upd.type === 'UpdateExpression' && isVar(upd.argument)) step = upd.operator === '++' ? 1 : -1;
      else if (upd.type === 'AssignmentExpression' && isVar(upd.left) && upd.right.type === 'Literal' && typeof upd.right.value === 'number' && Number.isInteger(upd.right.value)) step = upd.operator === '+=' ? upd.right.value : upd.operator === '-=' ? -upd.right.value : null;
      const bodyAssigns = b && (b.assigns > 0);
      const bound = test.right;
      const stable = isVar(test.left) && this.stableBound(bound, s.body) && Number.isInteger(step) && step !== 0;
      const intInit = this.intLike(init.declarations[0].init);
      if (b && !b.boxed && !bodyAssigns && stable && step !== null && intInit) {
        let rng = null; const a = this.expr(init.declarations[0].init), e = this.expr(bound);
        const ie = this.intLike(bound) ? e : `ceili(${e})`;
        if (step > 0 && test.operator === '<') rng = step === 1 ? (a === '0' ? `range(${ie})` : `range(${a}, ${ie})`) : `range(${a}, ${ie}, ${step})`;
        else if (step > 0 && test.operator === '<=') rng = `range(${a}, ${this.intLike(bound) ? e : `floori(${e})`} + 1${step === 1 ? '' : ', ' + step})`;
        else if (step < 0 && test.operator === '>=') rng = `range(${a}, ${this.intLike(bound) ? e : `ceili(${e})`} - 1, ${step})`;
        else if (step < 0 && test.operator === '>') rng = `range(${a}, ${this.intLike(bound) ? e : `floori(${e})`}, ${step})`;
        if (rng) {
          const nm = this.bindName(b); b.declared = true;
          this.loopStack.push({ type: 'for' });
          const body = this.body(s.body);
          this.loopStack.pop();
          return [`for ${nm} in ${rng}:\n${body}`];
        }
      }
    }
    // general form → while
    if (init) out.push(...(init.type === 'VariableDeclaration' ? this.stmt(init) : this.exprStmt(init)));
    // the loop variable now lives in the enclosing GDScript block
    if (s._scope && s._scope.parent) { const P = s._scope.parent; P.leaked = P.leaked || new Set(); for (const b of s._scope.b.values()) if (b.gd) P.leaked.add(b.gd); }
    const update = upd ? this.exprStmt(upd) : [];
    const [c, p] = test ? this.isolated(() => this.cond(test)) : ['true', []];
    this.loopStack.push({ type: 'for', update });
    let bodyText = this.body(s.body);
    this.loopStack.pop();
    if (bodyText.trim() === 'pass') bodyText = '';
    const tail = update.length ? ind(update.join('\n')) : '';
    const inner = [bodyText, tail].filter(x => x).join('\n') || ind('pass');
    if (!p.length) out.push(`while ${c}:\n${inner}`);
    else out.push(`while true:\n${ind([...p, `if not (${c}):`, T + 'break'].join('\n'))}\n${inner}`);
    return out;
  }
  intLike(n) {
    if (n.type === 'Literal') return Number.isInteger(n.value);
    if (n.type === 'MemberExpression' && !n.computed && n.property.name === 'length') return true;
    if (n.type === 'CallExpression' && n.callee.type === 'MemberExpression' && n.callee.object.type === 'Identifier' && n.callee.object.name === 'Math' && ['floor', 'ceil', 'round', 'trunc'].includes(n.callee.property.name)) return true;
    if (n.type === 'BinaryExpression' && ['+', '-', '*'].includes(n.operator)) return this.intLike(n.left) && this.intLike(n.right);
    if (n.type === 'UnaryExpression' && n.operator === '-') return this.intLike(n.argument);
    return false;
  }
  stableBound(bound, body) {
    if (bound.type === 'Literal') return true;
    if (bound.type === 'Identifier') { const b = bound._b; if (b) return b.assigns === 0 || !this.containsOwn(body, n => (n.type === 'AssignmentExpression' && n.left.type === 'Identifier' && n.left._b === b) || (n.type === 'UpdateExpression' && n.argument.type === 'Identifier' && n.argument._b === b)); return true; }
    if (bound.type === 'MemberExpression' && !bound.computed && bound.property.name === 'length') {
      // unstable if the body mutates anything via push/splice/pop/shift
      return !this.containsOwn(body, n => n.type === 'CallExpression' && n.callee.type === 'MemberExpression' && !n.callee.computed && ['push', 'splice', 'pop', 'shift', 'unshift'].includes(n.callee.property.name));
    }
    if (bound.type === 'BinaryExpression') return this.stableBound(bound.left, body) && this.stableBound(bound.right, body);
    if (bound.type === 'MemberExpression' && !bound.computed) return this.stableBound(bound.object, body) && !this.containsOwn(body, n => n.type === 'AssignmentExpression' && n.left.type === 'MemberExpression' && !n.left.computed && n.left.property.name === bound.property.name);
    return false;
  }
  forOf(s) {
    const [seq, pre] = this.isolated(() => this.expr(s.right));
    const head = [];
    let name;
    const left = s.left.type === 'VariableDeclaration' ? s.left.declarations[0].id : s.left;
    if (left.type === 'Identifier' && left._b && !left._b.boxed && s.left.type === 'VariableDeclaration') { name = this.bindName(left._b); left._b.declared = true; }
    else if (left.type === 'Identifier' || left.type === 'MemberExpression') { name = this.newTmp('_e'); head.push(`${this.lvalue(left)} = ${name}`); }
    else { name = this.newTmp('_e'); head.push(...this.destructure(left, null, s.left.type === 'VariableDeclaration', name)); }
    this.loopStack.push({ type: 'for' });
    const body = this.body(s.body, head);
    this.loopStack.pop();
    const it = s.type === 'ForInStatement' ? `JS.keys(${seq})` : `JS.iter(${seq})`;
    return [...pre, `for ${name} in ${it}:\n${body}`];
  }
  switchStmt(s) {
    const [d, pre] = this.isolated(() => this.expr(s.discriminant));
    const out = [...pre];
    // group cases: consecutive empty cases fall through to the next body
    const groups = []; let tests = [];
    for (const c of s.cases) {
      tests.push(c.test);
      if (c.consequent.length) { groups.push({ tests, body: c.consequent, node: c }); tests = []; }
    }
    if (tests.length) groups.push({ tests, body: [], node: null });
    const endsFlow = stmts => { const l = stmts[stmts.length - 1]; if (!l) return false; if (['BreakStatement', 'ReturnStatement', 'ContinueStatement', 'ThrowStatement'].includes(l.type)) return true; if (l.type === 'BlockStatement') return endsFlow(l.body); return false; };
    // a `break` that is not the final statement of its case needs loop-form
    let midBreak = false;
    for (const g of groups) {
      const strip = g.body.length === 1 && g.body[0].type === 'BlockStatement' ? g.body[0].body : g.body;
      const inner = strip.slice(0, endsFlow(strip) ? -1 : undefined);
      for (const st of inner) if (this.containsOwn(st, n => n.type === 'BreakStatement', true)) midBreak = true;
    }
    groups.forEach((g, i) => { if (i < groups.length - 1 && g.body.length && !endsFlow(g.body)) this.warn(g.node, 'switch fallthrough with code'); });
    const allLit = groups.every(g => g.tests.every(t => t === null || t.type === 'Literal' || (t.type === 'UnaryExpression' && t.argument.type === 'Literal')));
    const ctx = { type: 'switch', loopForm: midBreak };
    this.loopStack.push(ctx);
    const emitBody = (g) => {
      let b = g.body.length === 1 && g.body[0].type === 'BlockStatement' ? g.body[0] : null;
      let stmts = b ? b.body : g.body;
      if (stmts.length && stmts[stmts.length - 1].type === 'BreakStatement') stmts = stmts.slice(0, -1);
      let lines = [];
      if (b) { const fake = { type: 'BlockStatement', body: stmts, _scope: b._scope, start: b.start, end: b.end }; if (b._scope) b._scope.node = fake; lines = this.block(fake); }
      else for (const st of stmts) { lines.push(...this.comments(st)); lines.push(...this.stmt(st)); }
      if (!lines.some(l => !l.startsWith('#'))) lines.push('pass');
      return ind(lines.join('\n'));
    };
    let text;
    if (allLit && !midBreak) {
      text = `match ${d}:`;
      for (const g of groups) {
        const pats = g.tests.map(t => t === null ? '_' : this.expr(t));
        const hasDefault = pats.includes('_');
        text += `\n${T}${hasDefault ? '_' : pats.join(', ')}:\n${ind(emitBody(g))}`;
      }
    } else {
      const v = this.newTmp('_sw');
      out.push(`var ${v} = ${d}`);
      let first = true; const parts = [];
      for (const g of groups) {
        const isDefault = g.tests.includes(null);
        const condText = g.tests.filter(t => t !== null).map(t => `${v} == ${this.exprP(t)}`).join(' or ');
        if (isDefault) parts.push(`else:\n${emitBody(g)}`);
        else { parts.push(`${first ? 'if' : 'elif'} ${condText}:\n${emitBody(g)}`); first = false; }
      }
      const defIdx = parts.findIndex(p => p.startsWith('else:'));
      if (defIdx >= 0 && defIdx !== parts.length - 1) this.warn(s, 'switch default not last');
      text = parts.join('\n');
      if (first) text = text.replace(/^else:/, 'if true:');
      if (midBreak) text = `while true:\n${ind(text)}\n${T}break`;
    }
    this.loopStack.pop();
    out.push(text);
    return out;
  }

  // ───────────── module ─────────────
  module() {
    const mod = this.mod, ast = mod.ast;
    analyze(ast, mod);
    const header = [`# ${mod.name} — generated from ${mod.file} by tools/js2gd.js`, 'extends Node', ''];
    const members = [], boot = [], funcs = [];
    const ov = OVERRIDES[mod.name] || {};
    const seenFuncs = new Map();
    for (const s of ast.body) {
      this.cmin = this.lastEnd || 0;
      const lead = this.comments(s);
      this.lastEnd = s.end;
      if (s.type === 'FunctionDeclaration') {
        const name = safeGlobal(s.id.name);
        let text;
        if (ov[s.id.name]) { text = ov[s.id.name].trimEnd(); this.skipCommentsTo(s.end); }
        else {
          this.fnStack = []; this.pre = []; this.loopStack = [];
          const info = { usesThis: false, node: s }; this.fnStack.push(info);
          const { params, head } = this.params(s);
          const body = this.block(s.body, head);
          this.fnStack.pop();
          if (info.usesThis) body.unshift('var this = JS._this');
          text = `func ${name}(${params}):\n${ind((body.some(l => !l.startsWith('#')) ? body : [...body, 'pass']).join('\n'))}`;
        }
        const g = lookupGlobal(s.id.name, mod);
        if (g.node !== s) { // superseded by a later definition (another file or later in this one)
          text = text.replace(`func ${name}(`, `func ${name}__superseded_${mod.name}(`);
        }
        if (seenFuncs.has(name) && g.node === s) { // duplicate within file: rename the earlier
          const idx = seenFuncs.get(name); funcs[idx] = funcs[idx].replace(`func ${name}(`, `func ${name}__old(`);
        }
        seenFuncs.set(name, funcs.length);
        funcs.push([...lead, text].join('\n'));
        continue;
      }
      if (s.type === 'VariableDeclaration') {
        for (const d of s.declarations) {
          if (d.id.type !== 'Identifier') continue;
          const name = safeGlobal(d.id.name);
          const g = lookupGlobal(d.id.name, mod);
          const mine = g.node === d;
          const gname = mine ? name : `${name}__superseded_${mod.name}`;
          const simpleLit = d.init && (d.init.type === 'Literal' && !d.init.regex || (d.init.type === 'UnaryExpression' && d.init.operator === '-' && d.init.argument.type === 'Literal'));
          if (!d.init) { members.push(...lead.splice(0), `var ${gname} = null`); continue; }
          if (simpleLit) { members.push(...lead.splice(0), `var ${gname} = ${this.expr(d.init)}`); continue; }
          members.push(`var ${gname} = null`);
          this.inTopData = true; this.fnStack = []; this.pre = []; this.pathStack = [d.id.name];
          const v = this.expr(d.init);
          boot.push(...lead.splice(0), ...this.pre, `${gname} = ${v}`);
          this.pre = []; this.inTopData = false; this.pathStack = [];
        }
        continue;
      }
      // other top-level statements run at boot
      this.fnStack = []; this.pre = [];
      boot.push(...lead, ...this.stmt(s));
    }
    const out = [...header, ...members, ''];
    out.push(`func _boot():\n${ind((boot.some(l => !l.startsWith('#')) ? boot : [...boot, 'pass']).join('\n'))}`, '');
    for (const f of funcs) out.push(f, '');
    for (const h of this.hoisted) out.push(h, '');
    // extra hand-written functions for this module
    if (ov._extra) out.push(ov._extra.trimEnd(), '');
    return out.join('\n');
  }
}
function balanced(s) { let d = 0; for (const ch of s) { if (ch === '(') d++; else if (ch === ')') { d--; if (d < 0) return false; } } return d === 0; }

// ───────────────────────────── main ─────────────────────────────
classifyProps();
inferReturnTypes();
const only = (process.argv.find(a => a.startsWith('--only=')) || '').slice(7);
fs.mkdirSync(OUT, { recursive: true });
let total = 0;
for (const mod of mods) {
  const em = new Emitter(mod);
  CUR_MOD = mod;
  let text;
  try { text = em.module(); } catch (e) { console.error(`FAILED ${mod.file}: ${e.stack}`); continue; }
  if (only && !mod.file.includes(only)) continue;
  fs.writeFileSync(path.join(OUT, mod.name + '.gd'), text);
  total += text.split('\n').length;
}
{
  const g = [...GLOBALS].map(([k, v]) => `\t${JSON.stringify(k)}: [${JSON.stringify(v.mod.name)}, ${JSON.stringify(v.kind === 'func' ? 'f' : 'v')}, ${JSON.stringify(safeGlobal(k))}],`).join('\n');
  fs.writeFileSync(path.join(OUT, 'GameModules.gd'), `# GameModules — generated by tools/js2gd.js: module boot order and the table of global names\n# (used to resolve inline event handlers such as onclick=\"showLibrary()\").\nclass_name GameModules\nextends RefCounted\n\nconst ORDER := ${JSON.stringify(mods.map(m => m.name))}\n\nconst GLOBALS := {\n${g}\n}\n`);
}
fs.writeFileSync(path.join(__dirname, 'modules.json'), JSON.stringify({ modules: mods.map(m => m.name), files: mods.map(m => m.file), window: [...WINDOW_PROPS],
  globals: Object.fromEntries([...GLOBALS].map(([k, g]) => [k, [g.mod.name, g.kind === 'func' ? 'f' : 'v', safeGlobal(k)]])) }, null, 0));
const byMsg = {};
for (const w of warnings) { const k = w.replace(/^[^:]+:[^:]+: /, '').replace(/ .*/, m => m.length > 40 ? m.slice(0, 40) : m); (byMsg[k] = byMsg[k] || []).push(w); }
if (process.argv.includes('--warn')) console.log(warnings.join('\n'));
else { const groups = {}; for (const w of warnings) { const key = w.split(': ').slice(1).join(': ').split(' ').slice(0, 2).join(' '); groups[key] = (groups[key] || 0) + 1; } console.log(Object.entries(groups).sort((a, b) => b[1] - a[1]).map(e => `${e[1]}\t${e[0]}`).join('\n')); }
console.log(`wrote ${mods.length} modules, ${total} lines, ${warnings.length} warnings`);
