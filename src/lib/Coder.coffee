class Coder
    @category = 'coders'
    @option = 'coder'

    ###
    Default encode function from object to data
    @param {object} object — object with request
    @return {string} data — output data; object, encoded to string/buffer/whatever format
    ###
    encode: JSON.stringify

    ###
    Default decode function from data to object
    @param {string} data — input request in string/buffer/whatever format
    @return {object} object — decoded object from data
    ###
    decode: JSON.parse

    encodeKey: (request) ->
        request.key = @key
        JSON.stringify request

    decodeKey: (data) ->
        request = JSON.parse data
        if request.key isnt @key
            throw new Error "Wrong API Key"
        delete request.key
        request

    constructor: (key) ->
        if key
            @key = key
            @encode = @encodeKey
            @decode = @decodeKey