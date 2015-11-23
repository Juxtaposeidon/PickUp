class EventsController < ApplicationController
    before_action :current_user, :require_user, only: [:index, :show, :new, :edit]


  def index
    @events = Event.all
    @user = current_user
  end

  def join
    @new_user = User.find(current_user.id)
    @event = Event.find(params[:id])
    @event.users << @new_user unless @event.users.exists?(@new_user)
     UserMailer.event_confirm_email(User.find(current_user.id), @event).deliver_now
    redirect_to events_path
  end

  def create
    @event = Event.new(event_params)
    @event.creator_id = current_user.id
    if @event.save
      UserMailer.event_creation_email(User.find(current_user.id), @event).deliver_now
      @event.users << User.find(current_user.id)
      redirect_to events_path
    else
      flash[:notice] = @event.errors.full_messages
      redirect_to new_event_path
    end
  end

  def creator_leave
    p @event = Event.find(params[:id])
    p @host = @event.creator
    p @new_host = @event.users.last
    p @attendees = @event.users.size
    # p "*" * 50
    if @attendees > 1
      @event.update_attribute(:creator_id, @new_host.id)
      p 'a' * 50
      @event.users.destroy(User.find(current_user.id))
    else
      @event.destroy
      p 'b' * 50
    end
      redirect_to user_path(current_user)
     #if no one left delete event
  end

  def leave
    @event = Event.find(params[:id])

    if @event.creator_id == current_user.id
      p 'c' * 50
      creator_leave
    else
      @event.users.destroy(User.find(current_user.id))
      p 'd' * 50
      redirect_to user_path(current_user)
    end
  end


  def new
    @event = Event.new
  end

  def map
    coords = params[:latitude] + ", " + params[:longitude] #takes the longitude and lat from the AJAX call and concatenates them into a string
         coords
    @nearevents = Event.near(coords, 20, :order => "distance").limit(10) #Runs the coords in Geocoder to find all events within 20(2nd arg) miles. It then sorts them by distance and limits the return array to 10 items. This also passes @nearevents into the function below.
    respond_to do |format|
      format.js #Because there is an AJAX call, Rails pings map.js.erb. Go to map.js.erb
    end
    # session[:long] = params[:longitude]
    # session[:lat] = params[:latitude]
  end

  def show
    @event = Event.find(params[:id])
  end

  def destroy
    @event = Event.find(params[:id]).destroy
  end

  def update
    @event = Event.find(params[:id])
    @event.update_attributes(event_params)
    redirect_to @event
  end

  def edit
    @event = Event.find(params[:id])
  end

  private
    def event_params
      params.require(:event).permit(:event_name, :description, :sport, :start, :end, :date, :participants, :location)
    end
end
