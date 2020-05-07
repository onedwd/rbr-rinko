# rbr-rinko

## Updates from IOS 
Our (IOS) RBR Concertos and Maestro using RINKO oxygen sensors where the logger has been setup to output %sat are using a fixed CTD temperature from the start of the CTD file in the calculation of volts to %sat instead of real-time CTD temperature.  
In the Arctic where the temperature at startup could be 25C warmer than the water temperature, this can give you a reading of 60% saturation instead of 95%.  The %saturation value is used to calculate concentration in ml/l so concentration values are low as well.
Correct %sat can be calculated using Rinko voltage output, accessed by exporting data from the RSK file as Legacy > Raw txt.  If data have been downloaded in ‘mobile’ mode, the downloaded *.RSK file no longer has the raw voltage information and recalculations are not possible.
