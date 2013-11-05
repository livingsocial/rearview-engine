/**
 * Tag-closer extension for CodeMirror.
 *
 * This extension adds a "closeTag" utility function that can be used with key bindings to 
 * insert a matching end tag after the ">" character of a start tag has been typed.  It can
 * also complete "</" if a matching start tag is found.  It will correctly ignore signal
 * characters for empty tags, comments, CDATA, etc.
 *
 * The function depends on internal parser state to identify tags.  It is compatible with the
 * following CodeMirror modes and will ignore all others:
 * - htmlmixed
 * - xml
 *
 * See demos/closetag.html for a usage example.
 * 
 * @author Nathan Williams <nathan@nlwillia.net>
 * Contributed under the same license terms as CodeMirror.
 */

!function(){function e(e,t){return CodeMirror.innerMode(e.getMode(),t).state}function t(e,t,r,o){n(e,t,o)?(e.replaceSelection("\n\n</"+o+">","end"),e.indentLine(r.line+1),e.indentLine(r.line+2),e.setCursor({line:r.line+1,ch:e.getLine(r.line+1).length})):(e.replaceSelection("</"+o+">"),e.setCursor(r))}function n(e,t,n){return("undefined"==typeof t||null==t||1==t)&&(t=e.getOption("closeTagIndent")),t||(t=[]),-1!=o(t,n.toLowerCase())}function r(e,t,n){return"xml"==e.getOption("mode")?!0:(("undefined"==typeof t||null==t)&&(t=e.getOption("closeTagVoid")),t||(t=[]),-1==o(t,n.toLowerCase()))}function o(e,t){if(e.indexOf)return e.indexOf(t);for(var n=0,r=e.length;r>n;++n)if(e[n]==t)return n;return-1}function i(e,t,n){e.replaceSelection("/"+n+">"),e.setCursor({line:t.line,ch:t.ch+n.length+2})}CodeMirror.defaults.closeTagEnabled=!0,CodeMirror.defaults.closeTagIndent=["applet","blockquote","body","button","div","dl","fieldset","form","frameset","h1","h2","h3","h4","h5","h6","head","html","iframe","layer","legend","object","ol","p","select","table","ul"],CodeMirror.defaults.closeTagVoid=["area","base","br","col","command","embed","hr","img","input","keygen","link","meta","param","source","track","wbr"],CodeMirror.defineExtension("closeTag",function(n,o,l,a){if(!n.getOption("closeTagEnabled"))throw CodeMirror.Pass;var s=n.getCursor(),c=n.getTokenAt(s),d=e(n,c.state);if(d)if(">"==o){var f=d.type;if("tag"==c.className&&"closeTag"==f)throw CodeMirror.Pass;if(n.replaceSelection(">"),s={line:s.line,ch:s.ch+1},n.setCursor(s),c=n.getTokenAt(n.getCursor()),d=e(n,c.state),!d)throw CodeMirror.Pass;var f=d.type;if("tag"==c.className&&"selfcloseTag"!=f){var u=d.tagName;return u.length>0&&r(n,a,u)&&t(n,l,s,u),void 0}n.setSelection({line:s.line,ch:s.ch-1},s),n.replaceSelection("")}else if("/"==o&&"tag"==c.className&&"<"==c.string){var g=d.context,u=g?g.tagName:"";if(u.length>0)return i(n,s,u),void 0}throw CodeMirror.Pass})}();