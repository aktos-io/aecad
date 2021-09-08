# https://github.com/DVLP/localStorageDB
``
!function(){function e(t,o){return n?void(n.transaction("s").objectStore("s").get(t).onsuccess=function(e){var t=e.target.result&&e.target.result.v||null;o(t)}):void setTimeout(function(){e(t,o)},100)}var t=window.indexedDB||window.mozIndexedDB||window.webkitIndexedDB||window.msIndexedDB;if(!t)return void console.error("indexDB not supported");var n,o={k:"",v:""},r=t.open("d2",1);r.onsuccess=function(e){n=this.result},r.onerror=function(e){console.error("indexedDB request error"),console.log(e)},r.onupgradeneeded=function(e){n=null;var t=e.target.result.createObjectStore("s",{keyPath:"k"});t.transaction.oncomplete=function(e){n=e.target.db}},window.ldb={get:e,set:function(e,t){o.k=e,o.v=t,n.transaction("s","readwrite").objectStore("s").put(o)}}}();
``

export class LdbStorage
    (@prefix, ctx=null) -> 
        @context = ctx or this 

    set: (key, value) -> 
        ldb.set "#{@prefix}.#{key}", JSON.stringify value

    get: (key, callback) ~>
        ldb.get "#{@prefix}.#{key}", (value) ~> 
            if value 
                callback.call @context, JSON.parse that 
            else 
                callback.call @context, value 

    del: (key) -> 
        ldb.set "#{@prefix}.#{key}", void