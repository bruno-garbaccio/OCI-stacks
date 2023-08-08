{
    "backends": {
        "API_GATEWAY_BACKEND": {
            "description": "OCI API Gateway Backend",
            "servers": [
                {
                    "url": "{APIGWURL}",
                    "description": "Default Server",
                    "variables": {
                        "APIGWURL": {
                            "default": "${endpoint}"
                        }
                    },
                    "x-vb": {
                        "profiles": [
                            "base_configuration"
                        ],
                        "anonymousAccess": true
                    }
                }
            ]
        }
      }
}