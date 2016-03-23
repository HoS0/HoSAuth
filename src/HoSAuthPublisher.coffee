module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    class HoSAuthPublisher extends EventEmitter
        _amqpConnection: null

        constructor: (@_HoSAuthCom, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            @_options = {durable: true, autoDelete: true}
            isClosed = false
            super()

        connect: ()->
            connectionOk = amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}")

            connectionOk.then (conn)=>
                @_amqpConnection = conn
                return conn.createChannel()

            .then (ch)=>
                ch.on "close", () =>
                    isClosed = true
                ch.on "error", () =>
                    isClosed = true
                @publishChannel = ch
                @publishChannel.assertExchange(@_HoSAuthCom.HoSPull, 'topic', {durable: true})

            connectionOk.catch (err)=>
                @isClosed = true
                @emit('error', err)

        sendReply: (message, payload, to)->
            sendOption = message.properties
            @publishChannel.publish(@_HoSAuthCom.HoSPull, to, new Buffer(JSON.stringify payload),sendOption)
