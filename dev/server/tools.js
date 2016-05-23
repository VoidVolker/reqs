// global.m = function(s){ log.info(s);}

var t = Object.prototype.toString;
exports.isNumber    = function(s){  return s === s & t.call(s) === '[object Number]'  ; } // s === s - is chek for NaN (NaN is alwasy !== NaN)
exports.isString    = function(s){  return t.call(s) === '[object String]'  ; }
exports.isArray     = function(s){  return t.call(s) === '[object Array]'   ; }
exports.isObject    = function(s){  return t.call(s) === '[object Object]'  ; }
exports.isFunction  = function(s){  return t.call(s) === '[object Function]'; }
exports.isBoolean   = function(s){  return t.call(s) === '[object Boolean]'; }
exports.isType      = function(s,t){return t.call(s).slice(8, -1) === t; }
exports.typeOf      = function(s){  return t.call(s).slice(8, -1); }

exports.toBoolean = function toBoolean(v){
    return !(
        v === 'false' ||
        v === '0' ||
        v === 'null' ||
        v === '' ||
        v === 0 ||
        v === null ||
        v === false ||
        v === undefined ||
        v !== v // NaN -> false
    );
}

exports.toInt = function toInt(v){ return parseInt(v, 10) || 0}
exports.toFloat = function toFloat(f){ return parseFloat(f, 10) || 0 }

exports.randomInt = function(min, max)  {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

exports.dirExistsSync = function dirExistsSync(d) {
    if( fs.existsSync(d) ){
        return fs.statSync(d).isDirectory();
    } else {
        return false;
    }
}

