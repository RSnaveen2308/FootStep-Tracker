
clear m;
m = mobiledev;

m.AccelerationSensorEnabled = 1;
m.PositionSensorEnabled = 1;

m.Logging = 1;
pause(10);

m.Logging = 0;

[a, t] = accellog(m);
[lat, lon, time] = poslog(m);

save('step_data.mat','a','t','lat','lon','time');

x = a(:,1);
y = a(:,2);
z = a(:,3);
mag = sqrt(sum(x.^2 + y.^2 + z.^2, 2));

magNoG = mag - mean(mag);
[pks, locs] = findpeaks(magNoG, 'MinPeakHeight', std(magNoG));
numSteps = numel(pks);

figure;
plot(t, magNoG);
hold on;
plot(t(locs), pks, 'r', 'Marker', 'v', 'LineStyle', 'none');
title('Counting Steps');
xlabel('Time (s)');
ylabel('Acceleration Magnitude, No Gravity (m/s^2)'); 
hold off;

radius = 6371e3; 
latRad = deg2rad(lat);
lonRad = deg2rad(lon);

dLat = diff(latRad);
dLon = diff(lonRad);

a = sin(dLat/2).^2 + cos(latRad(1:end-1)) .* cos(latRad(2:end)) .* sin(dLon/2).^2;
c = 2 * atan2(sqrt(a), sqrt(1 - a));
distances = radius * c;

totalDistance = sum(distances);

figure;
geoplot(lat, lon, '-o');
title('Traveled Path');
grid on;


cumulativeDistance = [0; cumsum(distances)];
figure;
plot(cumulativeDistance, '-o');
title('Cumulative Distance Traveled');
xlabel('Data Point Index');
ylabel('Distance (m)');
grid on;

data = [magNoG(end), numSteps, totalDistance];
thingSpeakWrite(2870006, data, 'Fields', [1, 2, 3], 'WriteKey', 'ALXN4YQK4O7L64XG');

ChannelID = 2870006;
writeAPIKey = 'ALXN4YQK4O7L64XG';
readAPIKey = '50A280SMH3TU824D';
alertApiKey = 'TAK0LHgf+Dm+WHr8Yi/';

alertUrl = "https://api.thingspeak.com/alerts/send";
options = weboptions("HeaderFields", ["ThingSpeak-Alerts-API-Key", alertApiKey]);
alertSubject = sprintf("Footstep Tracker Alert");

[magNoG, timeStamps] = thingSpeakRead(ChannelID, 'numPoints', 40, 'ReadKey', readAPIKey);

minPeakHeight = std(magNoG);
[pks, locs] = findpeaks(magNoG, 'MinPeakHeight', minPeakHeight);
numSteps = numel(pks);

threshold_step = 10;
if numSteps > threshold_step
    alertBody = 'Good job!';
else
    alertBody = 'Need more exercise.';
end

try
    webwrite(alertUrl, "body", alertBody, "subject", alertSubject, options);
catch someException
    fprintf("Failed to send alert: %s\n", someException.message);
end
m.AccelerationSensorEnabled = 0;
m.PositionSensorEnabled = 0;
clear m;
