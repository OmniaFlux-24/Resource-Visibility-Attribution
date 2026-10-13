export function apiError(status,code,message,requestId){return Object.freeze({status,body:{code,message,requestId}});}
export function safeFailure(error,requestId){if(error?.message==='Forbidden')return apiError(403,'forbidden','Permission denied',requestId);return apiError(500,'internal_error','Request could not be completed',requestId);}
