using Toybox.Background;
using Toybox.System as Sys;
using Toybox.Communications as Comm;
using Toybox.Application as App;

// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system.
//
(:background)
class BackgroundServiceDelegate extends Sys.ServiceDelegate 
{
	hidden var _syncCounter = 0;
	hidden var _location;
	hidden var _received = {}; 
	 
	function initialize() 
	{
		Sys.ServiceDelegate.initialize();
	}
	
    function onTemporalEvent() 
    {
    	try
    	{
    		//var time = System.getClockTime();
    		//Sys.println(Lang.format("callback happened $1$:$2$:$3$", [time.hour, time.min, time.sec]));
    	
	    	// Request Currency
	    	//
	    	if (Setting.GetIsShowExchangeRate())
			{
				RequestExchangeRate();
			}
	    
	    	_location = Setting.GetLastKnownLocation();
	    	var apiKey = Setting.GetWeatherApiKey();
	    	
	    	if (_location == null)
	    	{
	    		return;
	    	}
	    	
			// Request Weather
			//
	    	if (apiKey != null && apiKey.length() > 0)
	    	{
				RequestWeather(apiKey, _location);
			}		
			
			// Request Location
			//
			if (Setting.GetIsShowCity())
			{
				// avoid unnecessary web requests
				// 
				var city = Setting.GetCity();
				if(city != null &&
					_location[0].toFloat() == city["lrloc"][0].toFloat() && 
					_location[1].toFloat() == city["lrloc"][1].toFloat())
				{
					return;
				}
				
				RequestLocation(_location);
			}
		}
		catch(ex)
		{
			Sys.println("temp event error: " + ex.getErrorMessage());
			_received.put("isErr", true);
			Background.exit(_received);
		}		
    }
    
    function RequestWeather(apiKey, location)
	{	
		var url = Lang.format(
			"https://ivan-b.com/garminapi/wf-service/weather?apiToken=$1$&lat=$2$&lon=$3$&did=$4$&v=$5$&fw=$6$&ciqv=$7$&dname=$8$&wapiKey=$9$", [
			//"localhost:5051/api/YAFace/weather?apiToken=$1$&lat=$2$&lon=$3$&did=$4$&v=$5$&fw=$6$&ciqv=$7$&dname=$8$&wapiKey=$9$", [
			Setting.GetWatchServerToken(),
			location[0],
			location[1],
			Sys.getDeviceSettings().uniqueIdentifier,
			Setting.GetAppVersion(),
			Lang.format("$1$.$2$", Sys.getDeviceSettings().firmwareVersion),
			Lang.format("$1$.$2$.$3$", Sys.getDeviceSettings().monkeyVersion),
			Setting.GetDeviceName(),
			Setting.GetWeatherApiKey()]);			
			
		//Sys.println(" :: weather request " + url);

        var options = {
          :method => Comm.HTTP_REQUEST_METHOD_GET,
          :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

		_syncCounter = _syncCounter + 1;
    	Comm.makeWebRequest(url, {}, options, method(:OnReceiveWeather));
	}  
	
	function OnReceiveWeather(responseCode, data)
	{
		try
		{
			//Sys.println("weather data" + data + "\n code: " + responseCode);
		
			if (responseCode == 200)
			{
				_received.put("weather", {
					"temp" => data["temperature"].toFloat(),
					"wndSpeed" => data["windSpeed"].toFloat(),
					"perception" => data["precipProbability"].toFloat() * 100,
					"condition" => data["icon"]});
			}
			else
			{
				_received.put("isErr", true);
			}
			
			if (responseCode == 403)
			{
				_received.put("isAuthErr", true);
			}
			
			_syncCounter = _syncCounter - 1;
			if (_syncCounter == 0)
			{
				Background.exit(_received);
			}
		}
		catch(ex)
		{
			Sys.println("get weather error : " + ex.getErrorMessage());
			_received.put("isErr", true);
			Background.exit(_received);
		}
	}
	
	function RequestLocation(location)
	{
		var url = Lang.format(
			"https://ivan-b.com/garminapi/wf-service/location?lat=$1$&lon=$2$&did=$3$&v=$4$&fw=$5$&ciqv=$6$&dname=$7$", [
			location[0],
			location[1],
			Sys.getDeviceSettings().uniqueIdentifier,
			Setting.GetAppVersion(),
			Lang.format("$1$.$2$", Sys.getDeviceSettings().firmwareVersion),
			Lang.format("$1$.$2$.$3$", Sys.getDeviceSettings().monkeyVersion),
			Setting.GetDeviceName()]); 	
			
		//Sys.println(" :: location request: " + url);	
			
        var options = {
          :method => Comm.HTTP_REQUEST_METHOD_GET,
          :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

		_syncCounter = _syncCounter + 1;
    	Comm.makeWebRequest(url, {}, options, method(:OnReceiveLocation));
	}
	
	function OnReceiveLocation(responseCode, data)
	{
		//Sys.println("loc data" + data + ", code=" + responseCode);
		try
		{
			if (responseCode == 200)
			{
				_received.put("city", { 
					"City" => data["cityName"],
					"lrloc" => _location});
			}
			else
			{
				_received.put("isErr", true);
			}
			
			
			if (responseCode == 403)
			{
				_received.put("isAuthErr", true);
			}
			
			_syncCounter = _syncCounter - 1;
			if (_syncCounter == 0)
			{
				Background.exit(_received);
			}
		}
		catch (ex)
		{
			Sys.println("get location error : " + ex.getErrorMessage());
			_received.put("isErr", true);
			Background.exit(_received);
		}
	}
	
	function RequestExchangeRate()
	{
		var url = Lang.format("https://api.exchangeratesapi.io/latest?base=$1$&symbols=$2$", [
			Setting.GetBaseCurrency(), 
			Setting.GetTargetCurrency()]);	
		 
		//Sys.println(" :: ex rate request: " + url);
		
		var options = {
        	:method => Comm.HTTP_REQUEST_METHOD_GET,
          	:responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
		};
		
		_syncCounter = _syncCounter + 1;
    	Comm.makeWebRequest(url, {}, options, method(:OnReceiveExchangeRate));
	}
	
	function OnReceiveExchangeRate(responseCode, data)
	{
		//Sys.println(" data = " + data);
		//Sys.println(" code = " + responseCode);
		try
		{
			if (responseCode == 200)
			{
				_received.put("exchange", {
					"ExchangeRate" => data["rates"][Setting.GetTargetCurrency()].toFloat()});
			}
			else
			{
				_received.put("isErr", true);
			}
			
			_syncCounter = _syncCounter - 1;
			if (_syncCounter == 0)
			{
				Background.exit(_received);
			}
		}
		catch(ex)
		{
			Sys.println("get ex rate error : " + ex.getErrorMessage());
			_received.put("isErr", true);
			Background.exit(_received);
		}
	}
}