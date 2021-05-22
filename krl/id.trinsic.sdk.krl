ruleset id.trinsic.sdk {
  meta {
    description <<
      A rudimentary KRL sdk
    >>
    configure using apiKey = ""
    provides listCredentials, createCredential
      , listVerifications, createVerificationFromPolicy
      , getVerification
  }
  global {
    url = "https://api.trinsic.id/credentials/v1/"
    listCredentials = function(connectionId,state,definitionId){
      http:get(url+"credentials",
        headers = {
          "Authorization": <<Bearer #{apiKey}>>,
          "Accept": "application/json"
          },
        qs = {
          "definitionId": definitionId,
          "state": state,
          "connectionId": connectionId
        }
      )
    }
    listVerifications = function(connectionId,policyId){
      http:get(url+"verifications/policy/"+policyId+"/connections/"+connectionId)
    }
    getVerification = function(policyId){
      http:get(url+"verifications/"+policyId,
        headers = {
          "Authorization": <<Bearer #{apiKey}>>,
          "Accept": "application/json"
          }
      )
    }
    createCredential = defaction(definitionId,credentialValues){
      http:post(url+"credentials",
        headers = {
          "Authorization": <<Bearer #{apiKey}>>,
          "Accept": "application/json"
          },
        json = {
          "definitionId": definitionId,
          "automaticIssuance": true,
          "credentialValues": credentialValues
        }
      ) setting(response)
      return response
    }
    createVerificationFromPolicy = defaction(policyId){
      http:put(url+"verifications/policy/"+policyId,
        headers = {
          "Authorization": <<Bearer #{apiKey}>>,
          "Accept": "application/json"
          }
      ) setting(response)
      return response
    }
  }
}
