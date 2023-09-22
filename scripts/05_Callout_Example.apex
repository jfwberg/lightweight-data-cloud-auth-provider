dcQuery();
dcMetadata();
debug();

private void dcQuery(){
	HttpRequest request = new HttpRequest();
	request.setEndPoint('callout:DC_ORG_01/api/v2/query');
	request.setMethod('POST');
	request.setHeader('Content-Type','application/json');
	request.setBody('{"sql" : "select 1"}');
	HttpResponse res = new HTTP().send(request);
	System.debug(res.getStatusCode());
	System.debug(res.getBody());
}

private void dcMetadata(){
	HttpRequest request = new HttpRequest();
	request.setEndPoint('callout:DC_ORG_01/api/v1/profile/metadata');
	request.setMethod('GET');
	request.setHeader('Content-Type','application/json');
	HttpResponse res = new HTTP().send(request);
	System.debug(res.getStatusCode());
	System.debug(res.getBody());
}

private void debug(){
	HttpRequest request = new HttpRequest();
	request.setEndPoint('callout:Debug/api/echo');
	request.setMethod('POST');
	request.setHeader('Content-Type','application/json');
	request.setBody('{"sql" : "select 1"}');
	HttpResponse res = new HTTP().send(request);
	System.debug(res.getStatusCode());
	System.debug(res.getBody());
}