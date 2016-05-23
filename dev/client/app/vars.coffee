$window = $()
$body = $()
id = {}
APP = {}
noop = ->

( (exports) ->
    t = Object.prototype.toString
    exports.isNumber    = (s) -> s is s and (t.call(s) is '[object Number]')
    exports.isString    = (s) -> t.call(s) is '[object String]'
    exports.isArray     = (s) -> t.call(s) is '[object Array]'
    exports.isObject    = (s) -> t.call(s) is '[object Object]'
    exports.isFunction  = (s) -> t.call(s) is '[object Function]'
    exports.isBoolean   = (s) -> t.call(s) is '[object Boolean]'
    exports.isType      = (s, t) -> t.call(s).slice(8, -1) is t
    exports.type        = (s) -> t.call(s).slice(8, -1)
    return
)(this)

Date.prototype.timeNow = () ->
    `((this.getHours() < 10)?"0":"") + this.getHours() +":"+ ((this.getMinutes() < 10)?"0":"") + this.getMinutes() +":"+ ((this.getSeconds() < 10)?"0":"") + this.getSeconds()`

getRandomInt = (min, max) -> Math.floor( Math.random() * (max - min + 1) ) + min


toBoolean = (v) -> not (
        v is 'false' or
        v is '0' or
        v is 'null' or
        v is '' or
        v is 0 or
        v is null or
        v is false or
        v is undefined or
        v isnt v
    )

toInt = (v) -> parseInt(v, 10) or 0
toFloat = (v) -> parseFloat(v, 10) or 0

