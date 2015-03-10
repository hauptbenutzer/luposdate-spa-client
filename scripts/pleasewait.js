!function(n,i){"object"==typeof exports?i(exports):"function"==typeof define&&define.amd?define(["exports"],i):i(n)}(this,function(n){var i,e,t,l,o,a,s,d,m,r,g,c,u,h;o=document.createElement("fakeelement"),t=!1,g=!1,e="animationend",r=null,l="Webkit Moz O ms".split(" "),m={WebkitTransition:"webkitTransitionEnd",MozTransition:"transitionend",OTransition:"oTransitionEnd",msTransition:"MSTransitionEnd",transition:"transitionend"};for(a in m)if(c=m[a],null!=o.style[a]){r=c,g=!0;break}if(null!=o.style.animationName&&(t=!0),!t)for(u=0,h=l.length;h>u;u++)if(s=l[u],null!=o.style[""+s+"AnimationName"]){switch(s){case"Webkit":e="webkitAnimationEnd";break;case"Moz":e="animationend";break;case"O":e="oanimationend";break;case"ms":e="MSAnimationEnd"}t=!0;break}return i=function(){function n(n){var i,l,o,a;i=this.constructor._defaultOptions,this.options={},this.loaded=!1;for(l in i)a=i[l],this.options[l]=null!=n[l]?n[l]:a;this._loadingElem=document.createElement("div"),this._loadingHtmlToDisplay=[],this._loadingElem.className="pg-loading-screen",null!=this.options.backgroundColor&&(this._loadingElem.style.backgroundColor=this.options.backgroundColor),this._loadingElem.innerHTML=this.options.template,this._loadingHtmlElem=this._loadingElem.getElementsByClassName("pg-loading-html")[0],null!=this._loadingHtmlElem&&(this._loadingHtmlElem.innerHTML=this.options.loadingHtml),this._readyToShowLoadingHtml=!1,this._logoElem=this._loadingElem.getElementsByClassName("pg-loading-logo")[0],null!=this._logoElem&&(this._logoElem.src=this.options.logo),document.body.className+=" pg-loading",document.body.appendChild(this._loadingElem),this._loadingElem.className+=" pg-loading",o=function(n){return function(){return n.loaded=!0,n._readyToShowLoadingHtml=!0,n._loadingHtmlElem.className+=" pg-loaded",t&&n._loadingHtmlElem.removeEventListener(e,o),n._loadingHtmlToDisplay.length>0?n._changeLoadingHtml():void 0}}(this),null!=this._loadingHtmlElem&&(t?this._loadingHtmlElem.addEventListener(e,o):o(),this._loadingHtmlListener=function(n){return function(){return n._readyToShowLoadingHtml=!0,n._loadingHtmlElem.className=n._loadingHtmlElem.className.replace(" pg-loading ",""),g&&n._loadingHtmlElem.removeEventListener(r,n._loadingHtmlListener),n._loadingHtmlToDisplay.length>0?n._changeLoadingHtml():void 0}}(this),this._removingHtmlListener=function(n){return function(){return n._loadingHtmlElem.innerHTML=n._loadingHtmlToDisplay.shift(),n._loadingHtmlElem.className=n._loadingHtmlElem.className.replace(" pg-removing "," pg-loading "),g?(n._loadingHtmlElem.removeEventListener(r,n._removingHtmlListener),n._loadingHtmlElem.addEventListener(r,n._loadingHtmlListener)):n._loadingHtmlListener()}}(this))}return n._defaultOptions={backgroundColor:null,logo:null,loadingHtml:null,template:"<div class='pg-loading-inner'>\n  <div class='pg-loading-center-outer'>\n    <div class='pg-loading-center-middle'>\n      <h1 class='pg-loading-logo-header'>\n        <img class='pg-loading-logo'></img>\n      </h1>\n      <div class='pg-loading-html'>\n      </div>\n    </div>\n  </div>\n</div>"},n.prototype.finish=function(n){var i;return null==n&&(n=!1),null!=this._loadingElem?this.loaded||n?this._finish():(i=function(n){return function(){return n._loadingElem.removeEventListener(e,i),window.setTimeout(function(){return n._finish()},1)}}(this),this._loadingHtmlElem.addEventListener(e,i)):void 0},n.prototype.updateOption=function(n,i){switch(n){case"backgroundColor":return this._loadingElem.style.backgroundColor=i;case"logo":return this._logoElem.src=i;case"loadingHtml":return this.updateLoadingHtml(i);default:throw new Error("Unknown option '"+n+"'")}},n.prototype.updateOptions=function(n){var i,e,t;null==n&&(n={}),t=[];for(i in n)e=n[i],t.push(this.updateOption(i,e));return t},n.prototype.updateLoadingHtml=function(n,i){if(null==i&&(i=!1),null==this._loadingHtmlElem)throw new Error("The loading template does not have an element of class 'pg-loading-html'");return i?(this._loadingHtmlToDisplay=[n],this._readyToShowLoadingHtml=!0):this._loadingHtmlToDisplay.push(n),this._readyToShowLoadingHtml?this._changeLoadingHtml():void 0},n.prototype._changeLoadingHtml=function(){return this._readyToShowLoadingHtml=!1,this._loadingHtmlElem.removeEventListener(r,this._loadingHtmlListener),this._loadingHtmlElem.removeEventListener(r,this._removingHtmlListener),this._loadingHtmlElem.className=this._loadingHtmlElem.className.replace(" pg-loading ","").replace(" pg-removing ",""),g?(this._loadingHtmlElem.className+=" pg-removing ",this._loadingHtmlElem.addEventListener(r,this._removingHtmlListener)):this._removingHtmlListener()},n.prototype._finish=function(){var n;return document.body.className+=" pg-loaded",n=function(i){return function(){return document.body.removeChild(i._loadingElem),document.body.className=document.body.className.replace("pg-loading",""),t&&i._loadingElem.removeEventListener(e,n),i._loadingElem=null}}(this),t?(this._loadingElem.className+=" pg-loaded",this._loadingElem.addEventListener(e,n)):n()},n}(),d=function(n){return null==n&&(n={}),new i(n)},n.pleaseWait=d,d}),this.pleaseWait=pleaseWait({logo:"images/logo.svg",backgroundColor:"#008CBA",loadingHtml:"<p class='loading-title'>Luposdate Web</p><div class='sk-spinner sk-spinner-cube-grid'> <div class='sk-cube'></div><div class='sk-cube'></div><div class='sk-cube'></div> <div class='sk-cube'></div><div class='sk-cube'></div><div class='sk-cube'></div> <div class='sk-cube'></div><div class='sk-cube'></div><div class='sk-cube'></div></div>"});