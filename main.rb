# encoding: utf-8

require 'rubygems'
require 'sinatra'
#require 'ruby-debug'
require 'pony' # for sending emails

require 'sinatra/base'
require 'hoptoad_notifier' #error notification

$LOAD_PATH.unshift File.dirname(__FILE__) + '/vendor/sequel'
require 'sequel'

HoptoadNotifier.configure do |config|
  config.api_key = '393def238f9ec5a38fb0d80087423988'
end

configure do
	Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://blog.db')

	require 'ostruct'
	Blog = OpenStruct.new(
		:title => 'CBIS news',
		:author => 'CBIS',
		#:url_base => 'http://localhost:4567/',
		:url_base => 'http://ischool.test.railshosting.cz/',
		:admin_password => 'cbis2010',
		:admin_cookie_key => 'cbis_admin',
		:admin_cookie_value => '913ace5851d6d976',
		:disqus_shortname => nil
	)
	
	set :environment, :production
  set :env, :production
  enable :logging, :dump_errors 
  
  use HoptoadNotifier::Rack
  enable :raise_errors
  
end

error do
	e = request.env['sinatra.error']
	puts e.to_s
	puts e.backtrace.join("\n")
	"Application error, please hit 'back' button. Errors are automatically reported, we will try to resolve them asap. Thank you."
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'post'

helpers do
	def admin?
		request.cookies[Blog.admin_cookie_key] == Blog.admin_cookie_value
	end

	def auth
		halt [ 401, 'Not authorized' ] unless admin?
	end
	
  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end
	
end

layout 'school_layout'

### Public

get '/news-original' do
	posts = Post.reverse_order(:created_at).limit(10)
	erb :news_original, :locals => { :posts => posts }, :layout => false
end

#get '/past/:year/:month/:day/:slug/' do
get '/news/:slug/' do
	post = Post.filter(:slug => params[:slug]).first
	halt [ 404, "Page not found" ] unless post
	@title = post.title
	if post.english == true
	  #erb :post, :locals => { :post => post }, :layout => false
	  cz = "/novinky"
	  erb :post, :layout => :lay_english, :locals => {:title => @title, :cz => cz, :post => post}
  else
    en = "/news"
    erb :prispevek, :layout => :lay_czech, :locals => {:title => @title, :en => en, :post => post}
  end
end

#get '/past/:year/:month/:day/:slug' do
get '/news/:slug' do
	#redirect "/past/#{params[:year]}/#{params[:month]}/#{params[:day]}/#{params[:slug]}/", 301
	redirect "/news/#{params[:slug]}/", 301
end

get '/past' do
	posts = Post.filter(:english => true).reverse_order(:created_at)
	@title = "Archive"
	erb :archive, :locals => { :posts => posts }, :layout => false
end

get '/archiv' do
  posts = Post.filter(:english => false).reverse_order(:created_at)
	@title = "Archiv"
	erb :archiv, :locals => { :posts => posts }, :layout => false
end

get '/past/tags/:tag' do
	tag = params[:tag]
	posts = Post.filter(:tags.like("%#{tag}%")).reverse_order(:created_at).limit(30)
	@title = "Posts tagged #{tag}"
	erb :tagged, :locals => { :posts => posts, :tag => tag }
end

get '/feed' do
	@posts = Post.filter(:english => true).reverse_order(:created_at).limit(20)
	content_type 'application/atom+xml', :charset => 'utf-8'
	builder :feed
end

get '/rss' do
	redirect '/feed', 301
end

get '/feedcz' do
	@posts = Post.filter(:english => false).reverse_order(:created_at).limit(20)
	content_type 'application/atom+xml', :charset => 'utf-8'
	builder :feed
end

get '/rsscz' do
	redirect '/feed', 301
end

### Admin

get '/auth' do
	erb :auth
end

post '/auth' do
	response.set_cookie(Blog.admin_cookie_key, Blog.admin_cookie_value) if params[:password] == Blog.admin_password
	redirect '/'
end

get '/posts/new' do
	#auth
	halt [ 401, 'Not authorized' ] unless admin?
	erb :edit, :locals => { :post => Post.new, :url => '/posts' }, :layout => :school_layout
end

post '/posts' do
	auth
	post = Post.new :title => params[:title], :tags => params[:tags], :body => params[:body], :created_at => Time.now, :slug => Post.make_slug(params[:title]), :english => params[:english]
	post.save
	redirect post.url
end

#get '/past/:year/:month/:day/:slug/edit' do
get '/news/:slug/edit' do
	auth
	post = Post.filter(:slug => params[:slug]).first
	halt [ 404, "Page not found" ] unless post
	erb :edit, :locals => { :post => post, :url => post.url }, :layout => :school_layout
end

#post '/past/:year/:month/:day/:slug/' do #update
post '/news/:slug/' do #update
	auth
	post = Post.filter(:slug => params[:slug]).first
	halt [ 404, "Page not found" ] unless post
	post.title = params[:title]
	post.tags = params[:tags]
	post.body = params[:body]
	post.english = params[:english]
	post.save
	redirect post.url
end

delete '/delete' do #delete
	auth
	post = Post.filter(:slug => params[:slug]).first
	halt [ 404, "Page not found" ] unless post
	english = post.english
	post.delete
	if english
	  redirect '/news'
  else
    redirect '/novinky'
  end
end

# skolka custom pages

get '/' do
  title = "English preschool and school in Olomouc, Czech Republic"
  cz = "/anglicka-skola-skolka"
  erb :index, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

get '/preschool' do
  title = "Preschool"
  cz = "/skolka"
  erb :preschool, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

get '/primary-school' do                                                    
  title = "Primary School"
  cz = "/skola"
  erb :primary_school, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

get '/gallery' do
  title = "Gallery"
  cz = "/galerie"
  erb :gallery, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

get '/contact' do
  title = "Contacts"
  cz = "/kontakty"
  erb :contact, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

get '/news' do
  posts = Post.filter(:english => true).reverse_order(:created_at).limit(5)
  title = "News"
  cz = "/novinky"
  erb :news, :locals => { :posts => posts, :title => title, :cz => cz }, :layout => :lay_english
end

get '/staff' do
  erb :staff, :layout => false
end

get '/staff2' do
  erb :staff2, :layout => false
end

post '/contact_submit' do
  Pony.mail(
    :to => 'info@ischool.cz', 
    :from => params[:contact], 
    :subject => 'Email from ischool.cz web', 
    :body => params[:body],
    :via => :smtp,
    :via_options => {
      :address        => "smtp.sendgrid.net",
      :port           => "25",
      :authentication => :plain,
      :user_name      => "app229083@heroku.com",
      :password       => "9d94ea7910e51706d0",
      :domain         => "ischool.cz"  
    }
  )
  #redirect '/contact'
  erb :contact, :locals => { :status => true, :title => "Contacts", :cz => "/kontakty" }, :layout => :lay_english
end

get '/expanding-preschool' do
  title = "expanding preschool capacity"
  cz = "/rozsireni-skolky"
  erb :expanding_preschool, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

# czech versions

get '/anglicka-skola-skolka' do
  title = "anglická školka a škola Olomouc"
  en = "/"
  erb :domu, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/skolka' do
  title = "Školka"
  en = "/preschool"
  erb :skolka, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/skola' do
  title = "Základní škola"
  en = "/primary-school"
  erb :skola, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/ucitele' do
  title = "Učitelé"
  en = "/staff"
  erb :ucitele, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/ucitele2' do
  title = "Učitelé 2"
  en = "/staff2"
  erb :ucitele2, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/kontakt' do
  title = "Kontakt"
  en = "/contact"
  erb :kontakt, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/novinky' do
  posts = Post.filter(:english => false).reverse_order(:created_at).limit(5)
  
  title = "Novinky"
  en = "/news"
  erb :novinky, :layout => :lay_czech, :locals => {:title => title, :en => en, :posts => posts}
end

get '/galerie' do
  title = "Galerie"
  en = "/gallery"
  erb :galerie, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/rozsireni-skolky' do
  title = "Rozšíření školky"
  en = "/expanding-preschool"
  erb :rozsireni_ms, :layout => :lay_czech, :locals => {:title => title, :en => en}
end
