require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe Remaining::ActAsForecast do
  describe "#calculate" do
    
    it "should not give a result if there is no changes" do
      forecast = create_valid_forecast
      forecast.calculate.should == nil
    end
    
    it "should take an optional argument to calculate with a target value (default is 0)" do
      forecast = create_valid_forecast
      forecast.calculate(3).should == nil
    end
    
    describe "when there are punctual uses" do
      before(:each) do
        @forecast = create_valid_forecast
        @hit_date = days_from_now(12)
        @forecast.changes << create_valid_change(:amount => 10, :date => now)
        @forecast.changes << create_valid_change(:amount => -1, :date => tomorrow)
        @forecast.changes << create_valid_change(:amount => -1, :date => days_from_now(3))
        @forecast.changes << create_valid_change(:amount => -3, :date => days_from_now(4))
        @forecast.changes << create_valid_change(:amount => -5, :date => @hit_date)
        @forecast.changes << create_valid_change(:amount => -23, :date => days_from_now(14))
      end
      
      it "should use the punctual uses to see which one in the future will pass the target value" do
        @forecast.calculate.should == [@hit_date] * 2
      end
      
      it "should use the punctual uses to see which one in the future will pass the target value" do
        @forecast.changes << create_valid_change(:amount => 50, :date => days_from_now(8))
        @forecast.calculate.should be_nil
      end
    end
    
    shared_examples_for "repeated uses" do
      before(:each) do
        @forecast = create_valid_forecast
        @forecast.changes << create_valid_change(:amount => 10, :date => now)
        @forecast.changes << create_valid_change(:amount => -1, :periodicity => "1d", :start_date => tomorrow, :end_date => @hit_date)
      end
      
      it "should create at least one interval with the non periodic change" do
        @forecast.send(:intervals).detect { |interval| interval.instance_variable_get("@changes").detect { |change| change.periodicity.nil? } }.should be_true
      end
      
      it "should have a first interval which total_changed should be +10" do
        @forecast.send(:intervals).first.total_changed.should == 10
      end
      
      it "should have a last interval which total_changed should be -1" do
        @forecast.send(:intervals).last.total_changed.should == -1
      end
      
      it "in 0 day, there should be 10 left" do
        @forecast.calculate(10).should == [now] * 2
      end
            
      it "in 2 days, there should be 9 left" do
        @forecast.calculate(9).should == [days_from_now(2), days_from_now(3)]
      end
      
      it "in 3 days, there should be 8 left" do
        @forecast.calculate(8).should == [days_from_now(3), days_from_now(4)]
      end
      
      it "in 4 days, there should be 7 left" do
        @forecast.calculate(7).should == [days_from_now(4), days_from_now(5)]
      end
      
      it "should find the date at which the target value is matched" do
        @forecast.calculate.should == [days_from_now(11), days_from_now(12)]
      end
    end
    
    describe "when there are repeated uses" do
      before(:each) do
        @hit_date = days_from_now(12)
      end
      
      it_should_behave_like "repeated uses"
    end
    
    describe "when there are unbounded repeated uses" do
      before(:each) do
        @hit_date = nil
      end
      
      it_should_behave_like "repeated uses"
    end
  end
  
  describe "#calculate_with_least_squares(target)" do
    it "should provide a date at which the target will be reached" do
      @forecast = create_valid_forecast
      @forecast.changes << create_valid_change(:amount => 5, :date => Time.at(0))
      @forecast.changes << create_valid_change(:amount => -1, :date => Time.at(1))
      @forecast.changes << create_valid_change(:amount => -1, :date => Time.at(2))
      @forecast.changes << create_valid_change(:amount => -1, :date => Time.at(3))
      @forecast.changes << create_valid_change(:amount => -1, :date => Time.at(4))
      @forecast.changes << create_valid_change(:amount => -1, :date =>Time.at(5))
      @forecast.calculate_with_least_squares.should == Time.at(5)
    end
    
    it "should return nil if the target would be reached before the first change" do
      @forecast = create_valid_forecast
      @forecast.changes << create_valid_change(:amount => 1, :date => Time.at(1))
      @forecast.changes << create_valid_change(:amount => 1, :date => Time.at(2))
      @forecast.changes << create_valid_change(:amount => 1, :date => Time.at(3))
      @forecast.changes << create_valid_change(:amount => 1, :date => Time.at(4))
      @forecast.changes << create_valid_change(:amount => 1, :date =>Time.at(5))
      @forecast.calculate_with_least_squares.should be_nil
    end
  end
  
  describe "#least_squares" do
    describe "when there are punctual uses" do
      it "should provide with the slope and offset" do
        @forecast = create_valid_forecast
        @forecast.changes << create_valid_change(:amount => 5, :date => Time.at(0))
        @forecast.changes << create_valid_change(:amount => -1, :date => Time.at(1))
        @forecast.changes << create_valid_change(:amount => -1, :date => Time.at(2))
        @forecast.changes << create_valid_change(:amount => -1, :date => Time.at( 3))
        @forecast.changes << create_valid_change(:amount => -1, :date => Time.at( 4))
        @forecast.changes << create_valid_change(:amount => -1, :date =>Time.at( 5))
        slope, offset = @forecast.least_squares
        slope.round.should == -1.0
        offset.round.should == 5
      end
    
    end
    
    describe "when there are repeated uses" do
      before(:each) do
        @forecast = create_valid_forecast
        @hit_date = now + 5
        @forecast.changes << create_valid_change(:amount => 5, :date => now)
        @forecast.changes << create_valid_change(:amount => -1, :periodicity => "1s", :start_date => now + 0.01, :end_date => @hit_date)
      end
      
      it "should provide with the slope and offset" do
        slope, offset = @forecast.least_squares
        slope.should be_within(0.01).of(-1.0)
        offset.should be_within(0.01).of(5)
      end
    end
    
    describe "when there are repeated, unbounded uses" do
      before(:each) do
        @forecast = create_valid_forecast
        @forecast.changes << create_valid_change(:amount => 5, :date => now)
        @forecast.changes << create_valid_change(:amount => -1, :periodicity => "1s", :start_date => now + 0.01, :end_date => nil)
      end
      
      it "should provide the slope and offset anyway" do
        slope, offset = @forecast.least_squares
        slope.should be_within(0.1).of(-1.0)
        offset.should be_within(0.2).of(5)
      end
    end
    
  end
end