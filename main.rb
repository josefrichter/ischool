require 'rubygems'
require 'sinatra'
#require 'ruby-debug'
require 'pony' # for sending emails

$LOAD_PATH.unshift File.dirname(__FILE__) + '/vendor/sequel'
require 'sequel'

configure do
	Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://blog.db')

	require 'ostruct'
	Blog = OpenStruct.new(
		:title => 'CBIS news',
		:author => 'CBIS',
		#:url_base => 'http://localhost:4567/',
		:url_base => 'http://ischool.heroku.com/',
		:admin_password => 'cbis2010',
		:admin_cookie_key => 'cbis_admin',
		:admin_cookie_value => '913ace5851d6d976',
		:disqus_shortname => nil
	)
	
	set :environment, :production
  set :env, :production
  enable :logging, :dump_errors 
end

error do
	e = request.env['sinatra.error']
	puts e.to_s
	puts e.backtrace.join("\n")
	"Application error"
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
end

layout 'school_layout'

### Public

get '/news-original' do
	posts = Post.reverse_order(:created_at).limit(10)
	erb :news_original, :locals => { :posts => posts }, :layout => false
end

get '/past/:year/:month/:day/:slug/' do
	post = Post.filter(:slug => params[:slug]).first
	halt [ 404, "Page not found" ] unless post
	@title = post.title
	if post.english == true
	  erb :post, :locals => { :post => post }, :layout => false
  else
    erb :prispevek, :locals => { :post => post }, :layout => false
  end
end

get '/past/:year/:month/:day/:slug' do
	redirect "/past/#{params[:year]}/#{params[:month]}/#{params[:day]}/#{params[:slug]}/", 301
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

get '/past/:year/:month/:day/:slug/edit' do
	auth
	post = Post.filter(:slug => params[:slug]).first
	halt [ 404, "Page not found" ] unless post
	erb :edit, :locals => { :post => post, :url => post.url }, :layout => :school_layout
end

post '/past/:year/:month/:day/:slug/' do #update
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
  erb :index, :layout => false
end

get '/preschool' do
  erb :preschool, :layout => false
end

get '/primary-school' do
  erb :primary_school, :layout => false
end

get '/gallery' do
  erb :gallery, :layout => false
end

get '/contact' do
  erb :contact, :layout => false
end

get '/news' do
  posts = Post.filter(:english => true).reverse_order(:created_at).limit(5)
  erb :news, :locals => { :posts => posts }, :layout => false
end

get '/staff' do
  erb :staff, :layout => false
end

get '/staff2' do
  erb :staff2, :layout => false
end

post '/contact_submit' do
  Pony.mail(
    :to => 'josef.richter@me.com', 
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
  erb :contact, :locals => { :status => true }, :layout => false
end

# czech versions

get '/domu' do
  erb :domu, :layout => false
end

get '/skolka' do
  erb :skolka, :layout => false
end

get '/skola' do
  erb :skola, :layout => false
end

get '/ucitele' do
  erb :ucitele, :layout => false
end

get '/ucitele2' do
  erb :ucitele2, :layout => false
end

get '/kontakt' do
  erb :kontakt, :layout => false
end

get '/novinky' do
  posts = Post.filter(:english => false).reverse_order(:created_at).limit(5)
  erb :novinky, :locals => { :posts => posts }, :layout => false
end

get '/galerie' do
  erb :galerie, :layout => false
end

