class MatchesController < ApplicationController
  include MatchesHelper
  # GET /matches
  # GET /matches.xml
  def index
    @matches = Match.page params[:page]
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @matches }
    end


  end
  def match_result_a(id)
    @result = Result.where(:match_id => id)
  end

  # GET /matches/1
  # GET /matches/1.xml
  def show
    @match = Match.find(params[:id])
    @result = Result.where(:match_id => params[:id])


    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @match }
    end
  end


  # GET /matches/new
  # GET /matches/new.xml
  def new   
    @unplayed = unplayed_playerdiv_players(get_playerdiv().division_id,current_player.id) # Get the unplayed players from current division.
    
    @players = 
    @match = Match.new
    1.times { @match.results.build }
    1.times { @match.rankings.build }
  
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @match }
    end
  end

  # GET /matches/1/edit
  def edit
    @match = Match.find(params[:id])
    @result = Result.where(:match_id => params[:id])
    0.times { @match.results.build }
  end

  # POST /matches
  # POST /matches.xml
  def create    
    #@unplayed = other_playerdiv_players_array(get_playerdiv().division_id,current_player.id)
    @unplayed = unplayed_playerdiv_players(get_playerdiv().division_id,current_player.id)
    #We need to edit the params here a bit!
    #Fix players 2s elo player_id, easypeasy.
    params['match']['rankings_attributes']['1']['player_id'] = params['match']['results_attributes']['1']['player_id']
    player1 = params['match']['results_attributes']['0']['player_id']
    player2 = params['match']['results_attributes']['1']['player_id']
    player1_score = params['match']['results_attributes']['0']['score']
    player2_score = params['match']['results_attributes']['1']['score']

    #Add new elo scores 
    if params['match']['results_attributes']['0']['score'] > params['match']['results_attributes']['1']['score']
      elo_scores = update_elo_score(params['match']['results_attributes']['0']['player_id'],params['match']['results_attributes']['1']['player_id']) 
      params['match']['rankings_attributes']['0']['score'] = elo_scores.first     
      params['match']['rankings_attributes']['1']['score'] = elo_scores.last
    elsif params['match']['results_attributes']['0']['score'] < params['match']['results_attributes']['1']['score']
      elo_scores = update_elo_score(params['match']['results_attributes']['1']['player_id'],params['match']['results_attributes']['0']['player_id']) 
      params['match']['rankings_attributes']['1']['score'] = elo_scores.first     
      params['match']['rankings_attributes']['0']['score'] = elo_scores.last
    elsif
      elo_scores = dont_update_elo_score(params['match']['results_attributes']['0']['player_id'],params['match']['results_attributes']['1']['player_id']) 
      params['match']['rankings_attributes']['0']['score'] = elo_scores.first     
      params['match']['rankings_attributes']['1']['score'] = elo_scores.last      
    end

    ## We want to break out and return to the new match page with a warning if the score is 3-3.
    if player1_score == "3" && player2_score == "3"
      respond_to do |format|
        format.html { redirect_to new_match_path, :alert => '3-3 is not a valid score' }
      end
    #  format.xml  { render :xml => @match.errors, :status => :unprocessable_entity }
    else      
      @match = Match.new(params[:match])
      respond_to do |format|
       if @match.save
         if Rails.env.production?
           player1_info = Player.find(player1)
           if player1_info.twitter.blank?
             player1_name = player1_info.name
           else 
             if player1_info.twitter.include? "@"
                player1_name = player1_info.twitter
              else 
                player1_name = ["@",player1_info.twitter].join("")
              end
           end

           player2_info = Player.find(player2)
           if player2_info.twitter.blank?
             player2_name = player2_info.name
           else 
             if player2_info.twitter.include? "@"
               player2_name = player2_info.twitter
             else 
               player2_name = ["@",player2_info.twitter].join("")
             end
           end
        end
## Messaging: sending tweets and emails.    
        if Rails.env.production?  
           ResultMailer.result_email(params['match']['rankings_attributes']['0']['player_id'],params['match']['rankings_attributes']['1']['player_id'],params['match']['results_attributes']['0']['score'],params['match']['results_attributes']['1']['score']).deliver
        end
        
        
        
        format.html { redirect_to(@match, :notice => "Your match has been entered successfully") }
        format.xml  { render :xml => @match, :status => :created, :location => @match }      
      else
        format.html { redirect_to new_match_path, :alert => 'You did not enter any scores' }
        format.xml  { render :xml => @match.errors, :status => :unprocessable_entity }
      end
    end
  end
end

  # PUT /matches/1
  # PUT /matches/1.xml
  def update
    @match = Match.find(params[:id])
    @result = Result.where(:match_id => params[:id])
    respond_to do |format|
      if @match.update_attributes(params[:match])
        format.html { redirect_to(@match, :notice => 'Match was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @match.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /matches/1
  # DELETE /matches/1.xml
  def destroy
    @match = Match.find(params[:id])
    @match.destroy

    respond_to do |format|
      format.html { redirect_to(root_to) }
      format.xml  { head :ok }
    end
  end
end
