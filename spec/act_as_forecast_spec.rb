require File.expand_path("spec_helper", File.dirname(__FILE__))

describe Remaining::ActAsForecast do
  describe ".calculate" do
    
    it "should not give a result if there is no changes" do
      forecast = create_valid_forecast
      forecast.calculate.should == nil
    end
    
    it "should take an optional argument to calculate with a target value (default is 0)" do
      pending
    end
    
    describe "when there are punctual uses" do
      before(:each) do
        @forecast = create_valid_forecast
        @hit_date = days_from_now(12)
        @forecast.changes = [create_valid_change(:amount => 10, :date => Time.now)]
        @forecast.changes << create_valid_change(:amount => -1, :date => tomorrow)
        @forecast.changes << create_valid_change(:amount => -1, :date => days_from_now(3))
        @forecast.changes << create_valid_change(:amount => -3, :date => days_from_now(4))
        @forecast.changes << create_valid_change(:amount => -5, :date => @hit_date)
        @forecast.changes << create_valid_change(:amount => -23, :date => days_from_now(14))
      end
      
      it "should use the punctual uses to see which one in the future will pass the target value" do
        @forecast.calculate.should == @hit_date
      end
      
      it "should use the punctual uses to see which one in the future will pass the target value" do
        @forecast.changes << create_valid_change(:amount => 50, :date => days_from_now(8))
        @forecast.calculate.should be_nil
      end
    end
    
    describe "when there are repeated uses" do
      before(:each) do
        @forecast = create_valid_forecast
        @hit_date = days_from_now(5)
        @forecast.changes = [create_valid_change(:amount => 10, :date => Time.now)]
        
        @forecast.changes << create_valid_change(:amount => -1, :periodicity => "1d", :start_date => tomorrow, :end_date => @hit_date)
      end
      
      it "should find the date at which the target value is matched" do
        @forecast.calculate.should == @hit_date
      end
    end
  end
  
  describe ".calculate_with_points" do
    it "" do
      pending
    end
  end
  
  describe ".least_squares" do
    describe "when there are punctual uses" do
      it "should provide with the slope and offset" do
        @forecast = create_valid_forecast
        @forecast.changes = [create_valid_change(:amount => 5, :date => Time.at(0))]
        @forecast.changes << create_valid_change(:amount => -1, :date => Time.at(1))
        @forecast.changes << create_valid_change(:amount => -1, :date => Time.at(2))
        @forecast.changes << create_valid_change(:amount => -1, :date => Time.at( 3))
        @forecast.changes << create_valid_change(:amount => -1, :date => Time.at( 4))
        @forecast.changes << create_valid_change(:amount => -1, :date =>Time.at( 5))
        slope, offset = @forecast.least_squares
        slope.round(4).should == -1.0
        offset.round(4).should == 5
      
      end
    
    end
    
    describe "when there are repeated uses" do
      before(:each) do
        @forecast = create_valid_forecast
        @hit_date = days_from_now(5)
        @forecast.changes = [create_valid_change(:amount => 10, :date => Time.now)]
        
        @forecast.changes << create_valid_change(:amount => -1, :periodicity => "1d", :start_date => tomorrow, :end_date => @hit_date)
      end
      
      it "should provide with the slope and offset" do
        slope, offset = @forecast.least_squares
        slope.round(4).should == -1.0
        offset.should == 5
      end
    end
    
  end
end