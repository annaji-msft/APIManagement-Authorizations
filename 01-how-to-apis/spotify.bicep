param apim_name string 


resource apim 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apim_name
}

// *******************
// One api
// *******************

resource spotify_api 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: 'spotify'
  parent: apim
  properties: {
    serviceUrl:'https://api.spotify.com'
    path: 'spotify'
    displayName:'spotify'
    protocols:[
      'https'
    ]
  }
}

// *******************
// Two operations
// *******************

resource spotify_api_getdata 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  name: 'getdata'
  parent: spotify_api
  properties: {
    method: 'GET'
    urlTemplate: '/data'
    displayName: 'getdata'
  }
}

resource spotify_api_gettoken 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  name: 'gettoken'
  parent: spotify_api
  properties: {
    method: 'GET'
    urlTemplate: '/token'
    displayName: 'gettoken'
  }
}

// *******************
// Three policies, one for api and two for each operation
// *******************

resource spotify_api_policy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  parent: spotify_api
  name: 'policy'
  properties: {
    value: api_policy
    format: 'xml'
    
  }
}

resource spotify_getdata_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-08-01' = {
  parent: spotify_api_getdata
  name: 'policy'
  properties: {
    value: operation_data_policy
    format: 'xml'
  }
}

resource spotify_gettoken_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-08-01' = {
  parent: spotify_api_gettoken
  name: 'policy'
  properties: {
    value: operation_token_policy
    format: 'xml'
  }
}
 

// *******************
// Three policies
// *******************
var api_policy = '''<policies>
<inbound>
    <base />
    <choose>
        <when condition="@(context.Request.Url.Query.GetValueOrDefault(&quot;idtype&quot;,&quot;managed&quot;).Equals(&quot;managed&quot;))">
            <get-authorization-context provider-id="@(context.Request.Url.Query.GetValueOrDefault(&quot;providerid&quot;,&quot;spotify-01&quot;))" authorization-id="@(context.Request.Url.Query.GetValueOrDefault(&quot;authid&quot;,&quot;auth-01&quot;))" context-variable-name="auth-context" ignore-error="false" identity-type="managed" />
        </when>
        <otherwise>
            <get-authorization-context provider-id="@(context.Request.Url.Query.GetValueOrDefault(&quot;providerid&quot;,&quot;spotify-01&quot;))" authorization-id="@(context.Request.Url.Query.GetValueOrDefault(&quot;authid&quot;,&quot;auth-01&quot;))" context-variable-name="auth-context" ignore-error="false" identity-type="jwt" identity="@(context.Request.Headers[&quot;Authorization&quot;][0].Replace(&quot;Bearer &quot;, &quot;&quot;))" />
        </otherwise>
    </choose>
    <set-header name="Content-Type" exists-action="override">
        <value>application/json</value>
    </set-header>
</inbound>
<backend>
    <base />
</backend>
<outbound>
    <base />
</outbound>
<on-error>
    <base />
</on-error>
</policies>'''


var operation_token_policy = '''<policies>
<inbound>
    <base />
    <return-response>
        <set-body>@(((Authorization)context.Variables.GetValueOrDefault(&quot;auth-context&quot;))?.AccessToken)</set-body>
    </return-response>
</inbound>
<backend>
    <base />
</backend>
<outbound>
    <base />
</outbound>
<on-error>
    <base />
</on-error>
</policies>'''


var operation_data_policy = '''<policies>
<inbound>
    <base />
    <set-header name="Authorization" exists-action="override">
        <value>@("Bearer " + ((Authorization)context.Variables.GetValueOrDefault(&quot;auth-context&quot;))?.AccessToken)</value>
    </set-header>
    <rewrite-uri template="/v1/me" copy-unmatched-params="false" />
</inbound>
<backend>
    <base />
</backend>
<outbound>
    <base />
</outbound>
<on-error>
    <base />
</on-error>
</policies>'''



