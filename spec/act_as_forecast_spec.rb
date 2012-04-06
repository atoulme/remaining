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
        @base_time = Time.now
        @hit_date = @base_time + 86400 * 12
        @forecast.changes = [create_valid_change(:amount => 10, :date => @base_time)]
        
        @forecast.changes << create_valid_change(:amount => -1, :periodicity => "1d", :start_date => @base_time + 86400, :end_date => @hit_date)
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
      
      it "should have a series of known intervals" do
        pending("Need to count the intervals")
        @forecast.send(:intervals).size.should == 11
      end
      
      it "in 0 day, there should be 10 left" do
        @forecast.calculate(10).should == (@base_time)
      end
            
      it "in 2 days, there should be 9 left" do
        @forecast.calculate(9).should == (@base_time + 86400 * 2)
      end
      
      it "in 3 days, there should be 8 left" do
        @forecast.calculate(8).should == (@base_time + 86400 * 3)
      end
      
      it "in 4 days, there should be 7 left" do
        @forecast.calculate(7).should == (@base_time + 86400 * 4)
      end
      
      it "should find the date at which the target value is matched" do
        @forecast.calculate.should == (@hit_date  - 86400)
      end
    end
  end
  
  describe ".calculate_with_least_squaresx" do
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
        slope.round.should == -1.0
        offset.round.should == 5
      
      end
    
    end
    
    describe "when there are repeated uses" do
      before(:each) do
        @forecast = create_valid_forecast
        @hit_date = Time.now + 5
        @forecast.changes = [create_valid_change(:amount => 5, :date => Time.now)]
        
        @forecast.changes << create_valid_change(:amount => -1, :periodicity => "1s", :start_date => Time.now, :end_date => @hit_date)
      end
      
      it "should provide with the slope and offset" do
        slope, offset = @forecast.least_squares
        slope.should be_within(0.01).of(-1.0)
        offset.should be_within(0.01).of(5)
      end
    end
    
  end
end