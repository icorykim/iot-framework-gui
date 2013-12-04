class UsersController < ApplicationController
	before_action :signed_in_user, only: [:index, :edit, :update, :destroy, :profile]
	before_action :correct_user, 	 only: [:edit, :update]
	before_action :admin_user, 		 only: :destroy


	def show
		@user = User.find_by_username(params[:id])
    cid = current_user.username
    res = Faraday.get "#{CONF['API_URL']}/users/#{cid}/streams/"
    @streams = JSON.parse(res.body)['streams']
    @count= @streams.length
	end

	def following
		@title = "Following"
		@user = User.find_by_username(params[:id])
    cid = current_user.username
		@relationships = Relationship.all.where(follower_id: cid)
		 @streams = @relationships.map do |r|
			url = "#{CONF['API_URL']}/streams/" + r.followed_id
			#logger.debug "*** url: #{url} ***"
			resp = Faraday.get url
			JSON.parse resp.body
			#logger.debug "*** parsed_resp: #{parsed_resp} ***"
		end
	end

	def new
		@user = User.new
    attributes = ["username"]
    attributes.each do |attr|
      @user.send("#{attr}=", nil)
    end
  end

	def create
		@user = User.new(user_params)
		if @user.save
			sign_in @user
      post
      flash[:success] = "Welcome to the Sample App!"
      redirect_to @user
		else
			render 'new'
		end
	end


	def profile
		@user = User.find_by_username(params[:username])
		render 'profile'
		@user.save
	end

	def update
		if @user.update_attributes(profile_params)
			flash[:success] = "Account updated"
			@user.save
			redirect_to @user
		else
			render 'edit'
		end
	end

	def destroy
		@user = User.find_by_username(params[:id])
		@user.destroy
		Relationship.all.where(followed_id: @user.username).each do |r|
			r.destroy
		end

		flash[:success] = "User destroyed."
		redirect_to users_url
	end

  def post
    url = "#{CONF['API_URL']}/users"
    send_data(:post, url)
  end

  def put
    url = "#{CONF['API_URL']}/users"
    send_data(:put, url)
  end
  

	private
		def index
			@users = User.paginate(page: params[:page])
		end

		def user_params
			params.require(:user).permit(:username, :email, :password, 
																	 :password_confirmation)
		end

		def profile_params
			params.require(:user).permit(:username, :email, :password, 
																	 :password_confirmation, :firstname, :lastname, :description)
		end
		# Before filters
		
		def signed_in_user
			unless signed_in?
				store_location
				flash[:warning] = "Please sign in"
				redirect_to signin_url
			end
		end

		def correct_user
			@user = User.find_by_username(params[:id])
			redirect_to(root_url) unless current_user?(@user)
		end

		def admin_user
			redirect_to(root_url) unless current_user.admin?
		end


    def send_data(method, url)
      new_connection unless @conn
      @conn.send(method) do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = '{"username" : "' + params[:user][:username] + '"}'
      end
    end

    def new_connection
      @conn = Faraday.new(:url => "#{CONF['API_URL']}/users") do |faraday|
        faraday.request  :url_encoded               # form-encode POST params
        faraday.response :logger                    # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter    # make requests with Net::HTTP
      end
    end
end
