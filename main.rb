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
  posts = Post.filter(:english => true).reverse_order(:created_at).limit(5)
  erb :index, :layout => :lay_english, :locals => {:title => title, :cz => cz, :posts => posts}
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
  cz = "/kontakt"
  erb :contact, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

get '/news' do
  posts = Post.filter(:english => true).reverse_order(:created_at).limit(4)
  title = "News"
  cz = "/novinky"
  erb :news, :locals => { :posts => posts, :title => title, :cz => cz }, :layout => :lay_english
end

get '/staff' do
  title = "Staff"
  cz = "/ucitele"
  erb :staff, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

get '/staff2' do
  title = "Staff2"
  cz = "/ucitele2"
  erb :staff2, :layout => :lay_english, :locals => {:title => title, :cz => cz}
  
end

get '/staff3' do
  title = "Staff3"
  cz = "/ucitele3"
  erb :staff3, :layout => :lay_english, :locals => {:title => title, :cz => cz}
  
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
  erb :contact, :locals => { :status => true, :title => "Contacts", :cz => "/kontakt" }, :layout => :lay_english
end

get '/expanding-preschool' do
  title = "expanding preschool capacity"
  cz = "/rozsireni-skolky"
  erb :expanding_preschool, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

get '/new-preschool-building' do
  title = "New building"
  cz = "/nova-budova-skolky"
  erb :newbuilding, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end

# czech versions

get '/domu' do
  redirect "/anglicka-skola-skolka", 301
end

get '/anglicka-skola-skolka' do
  title = "anglická školka a škola Olomouc"
  en = "/"
  posts = Post.filter(:english => false).reverse_order(:created_at).limit(4)
  erb :domu, :layout => :lay_czech, :locals => {:title => title, :en => en, :posts => posts}
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

get '/ucitele3' do
  title = "Učitelé 3"
  en = "/staff3"
  erb :ucitele3, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/kontakt' do
  title = "Kontakt"
  en = "/contact"
  erb :kontakt, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/novinky' do
  posts = Post.filter(:english => false).reverse_order(:created_at).limit(4)
  
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

get '/nova-budova-skolky' do
  title = "Nová budova školky"
  en = "/new-preschool-building"
  erb :novabudova, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/zakovska' do
  title = "Přihlášení do žákovské"
  en = "/homelog"
  erb :zakovska, :layout => :lay_czech, :locals => {:title => title, :en => en}
end

get '/homelog' do
  title = "Login to HomeLog"
  cz = "/zakovska"
  erb :homelog, :layout => :lay_english, :locals => {:title => title, :cz => cz}
end



#newsletter

get '/newsletter/st-venceslaus-term' do 
  erb :venceslaus, :layout => :'../lay_english', :locals => {:title => "St. Wenseslaus Term", :cz => "/newsletter/pololeti-svateho-vaclava"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/new-staff' do 
  erb :newstaff, :layout => :'../lay_english', :locals => {:title => "New Staff", :cz => "/newsletter/personalni-zmeny"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/circus-came-to-town' do 
  erb :circus, :layout => :'../lay_english', :locals => {:title => "Circus came to town", :cz => "/newsletter/prijel-cirkus"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/pips-and-aspects-assessments' do 
  erb :pips, :layout => :'../lay_english', :locals => {:title => "PIPS & ASPECTS Assessments", :cz => "/newsletter/vstupni-diagnosticke-testy"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/new-preschool-building' do 
  erb :newbuilding, :layout => :'../lay_english', :locals => {:title => "New Preschool Building", :cz => "/newsletter/nova-budova-skolky"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/survey-results' do 
  erb :surveyresults, :layout => :'../lay_english', :locals => {:title => "Survey results", :cz => "/newsletter/vysledky-pruzkumu"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/survey-results-2' do 
  erb :surveyresults2, :layout => :'../lay_english', :locals => {:title => "Survey results - continued", :cz => "/newsletter/vysledky-pruzkumu-2"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/survey-results-3' do 
  erb :surveyresults3, :layout => :'../lay_english', :locals => {:title => "Survey results - continued", :cz => "/newsletter/vysledky-pruzkumu-3"}, :views => settings.root+"/views/newsletter"
end

##cz

get '/newsletter/pololeti-svateho-vaclava' do 
  erb :vaclav, :layout => :'../lay_czech', :locals => {:title => "„Pololetí“ Svatého Václava", :en => "/newsletter/st-venceslaus-term"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/personalni-zmeny' do 
  erb :personal, :layout => :'../lay_czech', :locals => {:title => "Personální změny", :en => "/newsletter/new-staff"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/prijel-cirkus' do 
  erb :cirkus, :layout => :'../lay_czech', :locals => {:title => "Přijel Cirkus…", :en => "/newsletter/circus-came-to-town"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/vstupni-diagnosticke-testy' do 
  erb :testy, :layout => :'../lay_czech', :locals => {:title => "Vstupní diagnostické testy", :en => "/newsletter/pips-and-aspects-assessments"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/nova-budova-skolky' do 
  erb :novabudova, :layout => :'../lay_czech', :locals => {:title => "Nová budova školky", :en => "/newsletter/new-preschool-building"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/vysledky-pruzkumu' do 
  erb :vysledkypruzkumu, :layout => :'../lay_czech', :locals => {:title => "Výsledky průzkumu", :en => "/newsletter/survey-results"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/vysledky-pruzkumu-2' do 
  erb :vysledkypruzkumu2, :layout => :'../lay_czech', :locals => {:title => "Výsledky průzkumu - pokračování", :en => "/newsletter/survey-results-2"}, :views => settings.root+"/views/newsletter"
end

get '/newsletter/vysledky-pruzkumu-3' do 
  erb :vysledkypruzkumu3, :layout => :'../lay_czech', :locals => {:title => "Výsledky průzkumu - pokračování", :en => "/newsletter/survey-results-3"}, :views => settings.root+"/views/newsletter"
end
