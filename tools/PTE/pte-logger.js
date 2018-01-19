'use strict';

var winston = require('winston');

function PTELogger(opts) {
    var winstonLogger = new winston.Logger({
        transports: [
            new (winston.transports.Console)({ colorize: true })
        ]
    }),
        levels = ['debug', 'info', 'warn', 'error'],
        logger = Object.assign({}, winstonLogger);

    if (opts.level) {
        if (levels.includes(opts.level)) {
            // why, oh why, does logger.level = opts.level not work?
            winstonLogger.level = opts.level;
        }
    }

    levels.forEach(function (method) {
        var func = winstonLogger[method];

        logger[method] = (function (context, tag, f) {
            return function () {
                if (arguments.length > 0) {
                    var prefix = '[' + tag + ']: ';
                    arguments[0] = prefix + arguments[0];
                }

                f.apply(context, arguments);
            };
        }(winstonLogger, opts.prefix, func));
    });

    return logger;
}

module.exports = PTELogger;
