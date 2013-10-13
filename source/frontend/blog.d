module frontend.blog;


mixin template blog()
{	
	import std.regex;
	import std.functional;
	import vibe.d;
	import frontend.docs;
	import backend.idocs;
	
	void setupBlog()
	{
		router.get("/blog", &blog);
		router.get("/blog/*", &blogSingle);
	}
	
	void blog(HTTPServerRequest req, HTTPServerResponse res)
	{
		
		BlogDocument[] docs = new BlogDocument[0];
		
		foreach(each; docsProvider.queryBlogDocuments(-10))
		{
			BlogDocument doc = BlogDocument.fromBson(each);
			doc.fillAuthorInfo(usersProvider);
			
			docs ~= doc;
		}
		
		res.renderCompat!("ddust.blog.dt", HTTPServerRequest, "req", BlogDocument[], "docs")(req, docs);
	}
	
	public static void getMsg(out string msg, Exception ex)
	{
		msg = ex.msg;
	}
	
	void blogSingle(HTTPServerRequest req, HTTPServerResponse res)
	{		
		string path = req.fullURL().toString();
		
		auto m = split(path, r"/blog/");
		
		if (m.length < 2)
		{
			res.redirect("/blog", HTTPStatus.Forbidden);
			return;
		}
		
		if (m[1].length == 0)
		{
			return res.redirect("/blog");
		}
		else if (m[1].length != 24)
		{
			res.statusCode = HTTPStatus.NotFound;
			
			return;
		}
		
		
		auto id = BsonObjectID.fromString(m[1]);
		
		bool error = false;
		void onError(Exception ex)
		{
			if (cast(DocDoesntExist) ex)
			{
				res.statusCode = HTTPStatus.NotFound;
			}
			else throw ex;
			//res.statusPhrase = ex.msg;
			error = true;
			//throw new Exception(ex.msg);
		}
		
		Bson bdoc = docsProvider.queryBlogDocument(id, &onError);
		
		if (error) return;
		
		BlogDocument doc = BlogDocument.fromBson(bdoc);
		
		doc.fillAuthorInfo(usersProvider);
		
		Comment[] coms = new Comment[0];
		
		foreach(each; docsProvider.queryComments(BsonObjectID.fromString(m[1]), 10))
		{
			Comment com = Comment.fromBson(each);
			com.fillAuthorInfo(usersProvider);
			
			coms ~= com;
		}
		
		res.renderCompat!("ddust.blog.single.dt", HTTPServerRequest, "req", BlogDocument, "doc", Comment[],"coms")
			(req, doc, coms);
		
		
	}
}