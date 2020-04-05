class Tools

    t = Object.prototype.toString
    isArr = Array.isArray

    @isBoolean:     (v) -> t.call(v) is '[object Boolean]'
    @isString:      (v) -> t.call(v) is '[object String]'
    # @isArray:       (v) -> isArr v                                      # t.call(v) is '[object Array]'
    @isArray:       Array.isArray
    @isObject:      (v) -> t.call(v) is '[object Object]'
    @isFunction:    (v) -> t.call(v) is '[object Function]'
    @isNumber:      (v) -> v is v and (t.call(v) is '[object Number]')  # NaN === NaN -> false
    @typeOf:        (v) -> t.call(v).slice 8, -1                        # Attention! typeOf(NaN) === 'Number'
    @null:          (o) -> Object.assign Object.create(null), o

    # @isBoolean.type = 'Boolean'
    # @isString.type = 'String'
    # @isArray.type = 'Array'         # <- Reason of wrapping of Array.isArray
    # @isObject.type = 'Object'
    # @isFunction.type = 'Function'
    # @isNumber.type = 'Number'
