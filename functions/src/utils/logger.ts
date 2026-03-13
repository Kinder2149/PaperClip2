import * as logger from 'firebase-functions/logger';

export interface LogContext {
  uid?: string;
  worldId?: string;
  version?: number;
  operation?: string;
  duration?: number;
  [key: string]: any;
}

export class StructuredLogger {
  static info(message: string, context?: LogContext) {
    logger.info(message, context);
  }
  
  static warn(message: string, context?: LogContext) {
    logger.warn(message, context);
  }
  
  static error(message: string, error: Error, context?: LogContext) {
    logger.error(message, {
      ...context,
      error: error.message,
      stack: error.stack,
    });
  }
  
  static debug(message: string, context?: LogContext) {
    logger.debug(message, context);
  }
  
  // Helper pour mesurer la durée d'une opération
  static async timed<T>(
    operation: string,
    fn: () => Promise<T>,
    context?: LogContext
  ): Promise<T> {
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
    } catch (error) {
      const duration = Date.now() - start;
      
      this.error(`${operation} failed`, error as Error, {
        ...context,
        operation,
        duration,
        success: false,
      });
      
      throw error;
    }
  }
}
