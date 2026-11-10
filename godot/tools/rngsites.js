// Lists Math.random() call sites outside js/rendering with their enclosing top-level function.
const fs=require('fs'),path=require('path'),acorn=require('acorn');
const ROOT=path.resolve(__dirname,'../..');
const html=fs.readFileSync(path.join(ROOT,'index.html'),'utf8');
const files=[...html.matchAll(/<script src="([^"]+)"/g)].map(m=>m[1]);
const out={};
for(const f of files){
  const src=fs.readFileSync(path.join(ROOT,f),'utf8');
  const ast=acorn.parse(src,{ecmaVersion:'latest',locations:true});
  (function w(n,fn,usesCtx){
    if(!n||typeof n.type!=='string')return;
    if(n.type==='FunctionDeclaration'&&n.id){ fn=fn||n.id.name; }
    if(n.type==='CallExpression'&&n.callee.type==='MemberExpression'&&n.callee.object.name==='Math'&&n.callee.property.name==='random'){
      const k=f+' '+(fn||'<top>'); (out[k]=out[k]||[]).push(n.loc.start.line);
    }
    for(const k in n){ if(k==='loc')continue; const v=n[k]; if(Array.isArray(v))v.forEach(c=>w(c,fn)); else if(v&&typeof v.type==='string')w(v,fn); }
  })(ast,null);
}
for(const k of Object.keys(out)) console.log(k, out[k].length);
