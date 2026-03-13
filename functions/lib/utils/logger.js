"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.StructuredLogger = void 0;
const logger = __importStar(require("firebase-functions/logger"));
class StructuredLogger {
    static info(message, context) {
        logger.info(message, context);
    }
    static warn(message, context) {
        logger.warn(message, context);
    }
    static error(message, error, context) {
        logger.error(message, {
            ...context,
            error: error.message,
            stack: error.stack,
        });
    }
    static debug(message, context) {
        logger.debug(message, context);
    }
    // Helper pour mesurer la durée d'une opération
    static async timed(operation, fn, context) {
        const start = Date.now();
        try {
            const result = await fn();
            const duration = Date.now() - start;
            this.info(`${operation} completed`, {
                ...context,
                operation,
                duration,
                success: true,
            });
            return result;
        }
        catch (error) {
            const duration = Date.now() - start;
            this.error(`${operation} failed`, error, {
                ...context,
                operation,
                duration,
                success: false,
            });
            throw error;
        }
    }
}
exports.StructuredLogger = StructuredLogger;
