"""
Simple JSON-RPC client for the Logtalk Jupyter kernel.
"""

import json
import logging
from typing import Any, Dict, Optional, Union

# Set up logging
logger = logging.getLogger(__name__)

class JsonRpcClient:
    """A simple JSON-RPC 2.0 client implementation."""
    
    def __init__(self):
        self._request_id = 0
        
    def create_request(self, method: str, params: Optional[Union[list, dict]] = None) -> Dict[str, Any]:
        """Create a JSON-RPC request object."""
        self._request_id += 1
        request = {
            "jsonrpc": "2.0",
            "method": method,
            "id": self._request_id
        }
        if params is not None:
            request["params"] = params
        return request
    
    def parse_response(self, response_text: str) -> Dict[str, Any]:
        """Parse a JSON-RPC response."""
        try:
            response = json.loads(response_text)
            
            if not isinstance(response, dict):
                raise ValueError("Response must be a JSON object")
                
            if "jsonrpc" not in response or response["jsonrpc"] != "2.0":
                raise ValueError("Invalid or missing jsonrpc version")
                
            if "id" not in response:
                raise ValueError("Missing response id")
                
            if "error" in response:
                error = response["error"]
                logger.error(f"JSON-RPC error: {error.get('message', 'Unknown error')}")
                return {"error": error}
                
            if "result" not in response:
                raise ValueError("Response must have either 'result' or 'error'")
                
            return response
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON-RPC response: {e}")
            return {"error": {"code": -32700, "message": "Parse error"}}
        except ValueError as e:
            logger.error(f"Invalid JSON-RPC response: {e}")
            return {"error": {"code": -32603, "message": str(e)}}
        except Exception as e:
            logger.error(f"Unexpected error parsing JSON-RPC response: {e}")
            return {"error": {"code": -32603, "message": "Internal error"}}
            
    def format_request(self, method: str, params: Optional[Union[list, dict]] = None) -> str:
        """Create and format a JSON-RPC request as a string."""
        request = self.create_request(method, params)
        return json.dumps(request)
