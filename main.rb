# Blackjack Web Application for Tealeaf Academy Course 1 - Week 3
# Version 1.0
# Author: Clint Nelson


require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
  # Get the value of one or more cards. Takes: Array // Returns: int
  BLACKJACK_VAL = 21
  DEALERHIT_VAL = 17
  ACE_HIGH = 11
  ACE_LOW = 1


  def load_instvars
    @playername = session[:playername]
    @round = session[:round]
    @purse = session[:purse]
    @bet = session[:bet]
    @deck = session[:deck]
    @playercards = session[:playercards]
    @dealercards = session[:dealercards]
  end

  def calc_total(card_array)
    total = 0
    aces = 0
    card_array.each do |suit, val|
      if val == 'A'
        total += ACE_HIGH
        aces +=1
      else
        total += (val.to_i == 0? 10 : val.to_i)
      end
    end

    aces.times do
      break if total <= BLACKJACK_VAL
      total -=10
      # TODO trip boolean for BREAK.player
    end
    total
  end

  def card_image(card)
    suit =  case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = case card[1]
      when 'A' then 'ace'
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      else
        card[1]
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def win(msg, bkjk = false)
    if bkjk
      session[:purse] += (1.5*session[:bet]).to_i
      @success = "You hit BLACKJACK! Payout is 3:2!"
    else
      session[:purse] += session[:bet]
      @success = "#{msg} You WIN the round & $#{@bet}!"
    end

    session[:current] = false
    @purse = session[:purse]
    @hitstay = false
    @playerturn = false
    @playagain = true
  end

  def lose(msg)
    session[:purse] -= session[:bet]
    @purse = session[:purse]

    session[:current] = false
    @hitstay = false
    @playerturn = false
    @error = "#{msg} The dealer wins."
  end

  def tie(msg)
    session[:current] = false
    @hitstay = false
    @playerturn = false
    @success = "You tie & keep your bet!"
  end

  def gameover(msg)
    @error = "#{msg}"
    @gameover = true
  end
end




before do
  @playerturn = true
  @hitstay = true
  @playgain = false
end

# Unless this approach is "best-practice"
# Can someone let me know how to do this with conditionals on the 'gets'
# instead of doing it with if statements nested in a before statement?

#################### ROUTES ######################
#------------- ROOT DIRECTORY -----------
before '/' do
  (session[:hasleft] || session[:purse])? (redirect '/continue') : (redirect '/newgame')
  session[:playername].nil? ? (redirect '/newgame') : (redirect '/continue')
end

get '/' do
  redirect '/newgame'
end

#------------- NEW GAME ----------------
get '/newgame' do
  session.clear

  erb :newgame
end

post '/newgame' do
  if params[:playername].empty?
    @error = "Player name required."
    halt (erb :newgame)
  end

  session[:playername] = params[:playername]
  session[:round] = 0
  session[:purse] = 500

  redirect '/bet'
end

#------------- CONTINUE GAME -----------
get '/continue' do
  @hasleft = session[:hasleft]
  load_instvars

  if @purse == 0
    redirect '/newgame'
  end

  erb :continue
end


#------------- BETTING -----------------
get '/bet' do
  load_instvars

  erb :bet
end

post '/bet' do
  @bet = params[:bet]
  newbet = @bet.to_i

  if (newbet.nil?) && (session[:bet] > session[:purse])
    redirect '/bet'
  elsif (!newbet.nil?) && (newbet > session[:purse])
    redirect '/bet'
  elsif (!newbet.nil?) && (newbet == 0)
    redirect '/bet'
  else
      session[:bet] = @bet.to_i
  end

  redirect '/play'
end

#------------- PLAYING GAME -----------
get '/play' do
  if session[:current] == true
    load_instvars

    erb :play
  else
    session[:round] +=1
    session[:current] = true
    load_instvars

    # Building Deck
    suits = ['H', 'D', 'C', 'S']
    values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = suits.product(values).shuffle!
    @deck = session[:deck]

    # Deal Flop
    session[:dealercards] = []
    session[:playercards] = []

    session[:dealercards] << session[:deck].pop
    session[:playercards] << session[:deck].pop
    session[:dealercards] << session[:deck].pop
    session[:playercards] << session[:deck].pop

    # Update instance variables
    @playercards = session[:playercards]
    @dealercards = session[:dealercards]

    # Check for Blackjack
    if calc_total(@playercards) == BLACKJACK_VAL
      win("", true)
    end

    erb :play
  end
end

#------------- PLAYER HIT -------------
post '/play/player/hit' do
  load_instvars

  session[:playercards] << session[:deck].pop

  # Check if Bust
  if calc_total(@playercards) == BLACKJACK_VAL
    win("", true)

  elsif calc_total(@playercards) > BLACKJACK_VAL
    lose("You busted at #{calc_total(@player_cards)}.")

    # Offer to play again unless GAME OVER
    unless session[:purse] <= 0
      @playagain = true

      # GAME OVER
    else
      gameover("GAME OVER")
    end
  end

  erb :play
end

#-------------- PLAYER STAY (DEALER TURN) ---
post '/play/player/stay' do
  load_instvars

  # Dealer's turn
  @hitstay = false
  @playerturn = false
  session[:current] = false

  # Decide Play
  while (calc_total(@dealercards) < DEALERHIT_VAL) || (calc_total(@dealercards) < calc_total(@playercards))
    session[:dealercards] << session[:deck].pop
  end

  #decide game
  case
    when calc_total(@dealercards) > BLACKJACK_VAL
      win("Dealer busted!")
    when calc_total(@dealercards) < calc_total(@playercards)
      win("You have #{calc_total(@playercards)} points & the dealer has #{calc_total(@dealercards)}")
    when calc_total(@dealercards) > calc_total(@playercards)
      lose("The dealer has #{calc_total(@dealercards)}, and you have #{calc_total(@playercards)} points.")
      if session[:purse] == 0
        gameover("The dealer has #{calc_total(@dealercards)}, and you have #{calc_total(@playercards)} points. Dealer wins. GAME OVER")
      end
    else
      tie("")
  end

  # Play again
  if session[:purse] <= 0
    gameover("GAME OVER")
  else
    @playagain = true
  end

  erb :play
end

get '/exit' do
  load_instvars

  session[:hasleft] = true
  erb :exit
  #add boolean for "hasleft" to trigger a welcome on the '/bet' when they return
end




=begin
# Not related to this program, but here for convenient educational reference
get '/nested_template' do
  erb :"users/profile"
end

post '/myaction' do
  #typically inspect what was submitted from input box
  session[:sometext] = params[:sometext]
  #can check things here - such as verification of name for redirection
end
=end















































































































