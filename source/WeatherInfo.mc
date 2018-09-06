(:background)
class WeatherInfo
{
	var Temperature = 0;
	var WindSpeed = 0;
	var PerceptionProbability = 0;
	var Condition = "";
	var Status = 0;
	
	function ToDictionary()
	{
		return
		{
			"Temperature" => Temperature, 
			"WindSpeed" => WindSpeed, 
			"PerceptionProbability" => PerceptionProbability, 
			"Condition" => Condition, 
			"Status" => Status 
		};
	}
	
	function FromDictionary(dictionary)
	{
		Temperature = dictionary["Temperature"];
		WindSpeed = dictionary["WindSpeed"];
		PerceptionProbability = dictionary["PerceptionProbability"];
		Condition = dictionary["Condition"];
		Status = dictionary["Status"];
	}
}