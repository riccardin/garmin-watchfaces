import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
import Toybox.WatchUi;

class EpixStarterFaceView extends WatchUi.WatchFace {
    private const COLOR_CASE = 0xA8ACB2;
    private const COLOR_BEZEL = 0x62676D;
    private const COLOR_TRACK = 0xC9CDD2;
    private const COLOR_TICKS = 0xD4D7DB;
    private const COLOR_NUMERALS = 0xD8DBDF;
    private const COLOR_TEXT = 0xE2E3E5;
    private const COLOR_TEXT_DIM = 0xAEB4BD;
    private const COLOR_DATE_BG = 0xE7E7E3;
    private const COLOR_DATE_TEXT = 0x30343A;
    private const COLOR_DATE_BORDER = 0x7E848C;
    private const COLOR_WEATHER_ACCENT = 0xD3D7DC;
    private const COLOR_SLEEP_CASE = 0x2A2E33;
    private const COLOR_SLEEP_BEZEL = 0x10141A;
    private const COLOR_SLEEP_TRACK = 0x37414D;
    private const COLOR_SLEEP_TICKS = 0x4E5660;
    private const COLOR_SLEEP_NUMERALS = 0x6A7179;
    private const COLOR_SLEEP_TEXT = 0x68707A;
    private const COLOR_SLEEP_TEXT_DIM = 0x4F565F;
    private const COLOR_SLEEP_DATE_BG = 0x20262D;
    private const COLOR_SLEEP_DATE_TEXT = 0x868D96;
    private const COLOR_SLEEP_DATE_BORDER = 0x454C55;
    private const COLOR_SLEEP_WEATHER_ACCENT = 0x5B626B;
    private const COLOR_HAND = 0xD8DADF;
    private const COLOR_HAND_SHADOW = 0x0A0D11;
    private const COLOR_SECOND = 0xB9BEC5;
    private const COLOR_CENTER = 0x6E747B;
    private const COLOR_SLEEP_HAND = 0x7E848C;
    private const COLOR_SLEEP_MARKER = 0x5E646B;
    private var _isAwake as Boolean = true;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
        _isAwake = true;
    }

    function onUpdate(dc as Dc) as Void {
        var lowPowerMode = isLowPowerMode();
        drawFace(dc, !lowPowerMode, lowPowerMode);
    }

    function onPartialUpdate(dc as Dc) as Void {
        var lowPowerMode = isLowPowerMode();
        drawFace(dc, !lowPowerMode, lowPowerMode);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        _isAwake = true;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

    private function drawFace(dc as Dc, includeSeconds as Boolean, lowPowerMode as Boolean) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;
        var radius = ((width < height) ? width : height) / 2 - 8;
        var clockTime = System.getClockTime();
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (lowPowerMode) {
            drawSleepFace(dc, clockTime, cx, cy, radius, today.day as Number);
            return;
        }

        drawCase(dc, cx, cy, radius, false);
        drawDial(dc, cx, cy, radius - 6, false);
        drawMinuteTrack(dc, cx, cy, radius - 14, false);
        drawHourMarkers(dc, cx, cy, radius - 32, false);
        drawBranding(dc, cx, cy, false);
        drawDateWindow(dc, cx, cy, radius - 54, today.day as Number, false);
        drawHands(dc, cx, cy, radius - 42, clockTime, includeSeconds, false);
    }

    private function drawCase(dc as Dc, cx as Number, cy as Number, radius as Number, lowPowerMode as Boolean) as Void {
        var caseColor = lowPowerMode ? COLOR_SLEEP_CASE : COLOR_CASE;
        var bezelColor = lowPowerMode ? COLOR_SLEEP_BEZEL : COLOR_BEZEL;

        dc.setColor(caseColor, caseColor);
        dc.fillCircle(cx, cy, radius);

        dc.setColor(bezelColor, bezelColor);
        dc.fillCircle(cx, cy, radius - 4);

        dc.setColor(caseColor, bezelColor);
        dc.drawCircle(cx, cy, radius - 2);
        dc.drawCircle(cx, cy, radius - 7);
    }

    private function drawDial(dc as Dc, cx as Number, cy as Number, radius as Number, lowPowerMode as Boolean) as Void {
        var dialColors = lowPowerMode
            ? [0x0A1018, 0x091018, 0x081018, 0x070E15, 0x060C12, 0x050A10, 0x04080D]
            : [0x14253C, 0x13243A, 0x122238, 0x102035, 0x0E1C31, 0x0B1728, 0x08111D];
        var trackColor = lowPowerMode ? COLOR_SLEEP_TRACK : COLOR_TRACK;
        var dialBaseColor = lowPowerMode ? 0x04080D : 0x08111D;
        var steps = dialColors.size();

        for (var i = 0; i < steps; i += 1) {
            var circleRadius = radius - ((radius * i) / steps);
            dc.setColor(dialColors[i], dialColors[i]);
            dc.fillCircle(cx, cy, circleRadius);
        }

        dc.setColor(trackColor, dialBaseColor);
        dc.drawCircle(cx, cy, radius - 1);
        dc.drawCircle(cx, cy, radius - 14);
    }

    private function drawMinuteTrack(dc as Dc, cx as Number, cy as Number, radius as Number, lowPowerMode as Boolean) as Void {
        var tickColor = lowPowerMode ? COLOR_SLEEP_TICKS : COLOR_TICKS;

        for (var i = 0; i < 60; i += 1) {
            var angle = getAngleForIndex(i, 60.0);
            var isMajor = (i % 5) == 0;
            var outer = polarPoint(cx, cy, radius, angle);
            var inner = polarPoint(cx, cy, radius - (isMajor ? 12 : 6), angle);

            dc.setColor(tickColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(isMajor ? 2 : 1);
            dc.drawLine(outer[0], outer[1], inner[0], inner[1]);
        }

        dc.setPenWidth(1);
    }

    private function drawHourMarkers(dc as Dc, cx as Number, cy as Number, radius as Number, lowPowerMode as Boolean) as Void {
        var markerColor = lowPowerMode ? COLOR_SLEEP_NUMERALS : COLOR_NUMERALS;

        for (var i = 0; i < 12; i += 1) {
            if (i == 0 || i == 3 || i == 6 || i == 9) {
                continue;
            }

            var angle = getAngleForIndex(i, 12.0);
            var markerCenter = polarPoint(cx, cy, radius, angle);
            var innerCenter = polarPoint(cx, cy, radius - 18, angle);
            var dx = innerCenter[0] - markerCenter[0];
            var dy = innerCenter[1] - markerCenter[1];
            var length = Math.sqrt((dx * dx) + (dy * dy));
            var ux = dx / length;
            var uy = dy / length;
            var px = -uy;
            var py = ux;
            var halfWidth = 4;

            dc.setColor(markerColor, markerColor);
            dc.fillPolygon([
                [(markerCenter[0] + (px * halfWidth)).toNumber(), (markerCenter[1] + (py * halfWidth)).toNumber()],
                [(innerCenter[0] + (px * halfWidth)).toNumber(), (innerCenter[1] + (py * halfWidth)).toNumber()],
                [(innerCenter[0] - (px * halfWidth)).toNumber(), (innerCenter[1] - (py * halfWidth)).toNumber()],
                [(markerCenter[0] - (px * halfWidth)).toNumber(), (markerCenter[1] - (py * halfWidth)).toNumber()]
            ]);
        }

        drawRoman(dc, cx, cy - radius + 12, "XII", Graphics.FONT_LARGE, lowPowerMode);
        drawRoman(dc, cx + radius - 1, cy, "III", Graphics.FONT_LARGE, lowPowerMode);
        drawRoman(dc, cx, cy + radius - 4, "VI", Graphics.FONT_LARGE, lowPowerMode);
        drawRoman(dc, cx - radius + 8, cy, "IX", Graphics.FONT_LARGE, lowPowerMode);
    }

    private function drawRoman(dc as Dc, x as Number, y as Number, text as String, font as FontType, lowPowerMode as Boolean) as Void {
        dc.setColor(lowPowerMode ? COLOR_SLEEP_NUMERALS : COLOR_NUMERALS, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawBranding(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        var textColor = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;

        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 52, Graphics.FONT_MEDIUM, "EPIX", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy - 30, Graphics.FONT_XTINY, "Automatic", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var weatherDisplay = getWeatherDisplay();
        drawWeatherLine(dc, cx + 14, cy + 72, weatherDisplay[0], weatherDisplay[1], lowPowerMode);
    }

    private function drawDateWindow(dc as Dc, cx as Number, cy as Number, radius as Number, day as Number, lowPowerMode as Boolean) as Void {
        var datePoint = polarPoint(cx, cy, radius, getAngleForIndex(15, 60.0));
        var dateX = datePoint[0] - 18;
        var dateY = datePoint[1] + 1;
        var boxWidth = 28;
        var boxHeight = 20;
        var left = dateX - (boxWidth / 2);
        var top = dateY - (boxHeight / 2);

        dc.setColor(lowPowerMode ? COLOR_SLEEP_DATE_BG : COLOR_DATE_BG, lowPowerMode ? COLOR_SLEEP_DATE_BG : COLOR_DATE_BG);
        dc.fillRoundedRectangle(left, top, boxWidth, boxHeight, 4);
        dc.setColor(lowPowerMode ? COLOR_SLEEP_DATE_BORDER : COLOR_DATE_BORDER, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(left, top, boxWidth, boxHeight, 4);

        dc.setColor(lowPowerMode ? COLOR_SLEEP_DATE_TEXT : COLOR_DATE_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dateX - 1, dateY + 1, Graphics.FONT_TINY, day.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawSleepFace(dc as Dc, clockTime as ClockTime, cx as Number, cy as Number, radius as Number, day as Number) as Void {
        var offset = getSleepOffset(clockTime.min);
        var sleepCx = cx + offset[0];
        var sleepCy = cy + offset[1];

        drawCase(dc, sleepCx, sleepCy, radius, true);
        drawDial(dc, sleepCx, sleepCy, radius - 6, true);
        drawMinuteTrack(dc, sleepCx, sleepCy, radius - 14, true);
        drawHourMarkers(dc, sleepCx, sleepCy, radius - 32, true);
        drawBranding(dc, sleepCx, sleepCy, true);
        drawDateWindow(dc, sleepCx, sleepCy, radius - 54, day, true);
        drawHands(dc, sleepCx, sleepCy, radius - 42, clockTime, false, true);
    }

    private function drawSleepMarkers(dc as Dc, cx as Number, cy as Number, radius as Number) as Void {
        var positions = [0, 15, 30, 45];

        dc.setColor(COLOR_SLEEP_MARKER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        for (var i = 0; i < positions.size(); i += 1) {
            var angle = getAngleForIndex(positions[i], 60.0);
            var outer = polarPoint(cx, cy, radius, angle);
            var inner = polarPoint(cx, cy, radius - 10, angle);
            dc.drawLine(outer[0], outer[1], inner[0], inner[1]);
        }
    }

    private function drawHands(dc as Dc, cx as Number, cy as Number, radius as Number, clockTime as ClockTime, includeSeconds as Boolean, lowPowerMode as Boolean) as Void {
        var minuteAngle = getAngleForIndex(clockTime.min, 60.0);
        var hourValue = ((clockTime.hour % 12) * 60.0) + clockTime.min;
        var hourAngle = getAngleForIndex(hourValue, 12.0 * 60.0);
        var handColor = lowPowerMode ? COLOR_SLEEP_HAND : COLOR_HAND;

        drawHand(dc, cx, cy, hourAngle, radius * 0.46, 16, 7, handColor, !lowPowerMode);
        drawHand(dc, cx, cy, minuteAngle, radius * 0.72, 20, 5, handColor, !lowPowerMode);

        if (includeSeconds) {
            var secondAngle = getAngleForIndex(clockTime.sec, 60.0);
            drawHand(dc, cx, cy, secondAngle, radius * 0.82, 26, 2, COLOR_SECOND, false);
        }

        if (!lowPowerMode) {
            dc.setColor(COLOR_CENTER, COLOR_CENTER);
            dc.fillCircle(cx, cy, 7);
            dc.setColor(COLOR_HAND, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy, 7);
            dc.fillCircle(cx, cy, 2);
        }
    }

    private function drawHand(dc as Dc, cx as Numeric, cy as Numeric, angle as Numeric, length as Numeric, tail as Numeric, halfWidth as Numeric, color as Number, withShadow as Boolean) as Void {
        var tip = polarPoint(cx, cy, length, angle);
        var tailPoint = polarPoint(cx, cy, -tail, angle);
        var shaft = polarPoint(cx, cy, length * 0.18, angle);
        var perpAngle = angle + (Math.PI / 2.0);
        var frontLeft = polarPoint(shaft[0], shaft[1], halfWidth, perpAngle);
        var frontRight = polarPoint(shaft[0], shaft[1], -halfWidth, perpAngle);
        var backLeft = polarPoint(tailPoint[0], tailPoint[1], halfWidth * 0.75, perpAngle);
        var backRight = polarPoint(tailPoint[0], tailPoint[1], -halfWidth * 0.75, perpAngle);
        var handPoints = new Array<[Numeric, Numeric]>[5];

        handPoints[0] = backLeft;
        handPoints[1] = frontLeft;
        handPoints[2] = tip;
        handPoints[3] = frontRight;
        handPoints[4] = backRight;

        if (withShadow) {
            var shadowOffset = 2;
            var shadowPoints = new Array<[Numeric, Numeric]>[5];

            shadowPoints[0] = makePoint(backLeft[0] + shadowOffset, backLeft[1] + shadowOffset);
            shadowPoints[1] = makePoint(frontLeft[0] + shadowOffset, frontLeft[1] + shadowOffset);
            shadowPoints[2] = makePoint(tip[0] + shadowOffset, tip[1] + shadowOffset);
            shadowPoints[3] = makePoint(frontRight[0] + shadowOffset, frontRight[1] + shadowOffset);
            shadowPoints[4] = makePoint(backRight[0] + shadowOffset, backRight[1] + shadowOffset);

            dc.setColor(COLOR_HAND_SHADOW, COLOR_HAND_SHADOW);
            dc.fillPolygon(shadowPoints);
        }

        dc.setColor(color, color);
        dc.fillPolygon(handPoints);
    }

    private function polarPoint(cx as Numeric, cy as Numeric, distance as Numeric, angle as Numeric) as [Numeric, Numeric] {
        var angleFloat = angle.toFloat();
        var x = cx + (Math.cos(angleFloat) * distance);
        var y = cy + (Math.sin(angleFloat) * distance);
        return makePoint(x.toNumber(), y.toNumber());
    }

    private function makePoint(x as Numeric, y as Numeric) as [Numeric, Numeric] {
        return [x, y];
    }

    private function getAngleForIndex(index as Numeric, units as Numeric) as Float {
        return ((((index / units) * Math.PI * 2.0) - (Math.PI / 2.0)) as Numeric).toFloat();
    }

    private function drawWeatherLine(dc as Dc, cx as Number, y as Number, weatherLabel as String, iconKey as String, lowPowerMode as Boolean) as Void {
        drawWeatherIcon(dc, cx - 28, y, iconKey, lowPowerMode);
        dc.setColor(lowPowerMode ? COLOR_SLEEP_TEXT_DIM : COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 4, y, Graphics.FONT_XTINY, weatherLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawWeatherIcon(dc as Dc, cx as Number, cy as Number, iconKey as String, lowPowerMode as Boolean) as Void {
        if (iconKey == "CLEAR") {
            drawSunIcon(dc, cx, cy, lowPowerMode);
        } else if (iconKey == "PARTLY") {
            drawSunIcon(dc, cx - 4, cy - 3, lowPowerMode);
            drawCloudIcon(dc, cx + 1, cy + 1, lowPowerMode);
        } else if (iconKey == "CLOUDY") {
            drawCloudIcon(dc, cx, cy, lowPowerMode);
        } else if (iconKey == "RAIN") {
            drawCloudIcon(dc, cx, cy - 1, lowPowerMode);
            drawRainIcon(dc, cx, cy + 4, lowPowerMode);
        } else if (iconKey == "STORM") {
            drawCloudIcon(dc, cx, cy - 2, lowPowerMode);
            drawStormBolt(dc, cx + 1, cy + 4, lowPowerMode);
        } else if (iconKey == "SNOW") {
            drawCloudIcon(dc, cx, cy - 1, lowPowerMode);
            drawSnowIcon(dc, cx, cy + 5, lowPowerMode);
        } else if (iconKey == "WIND") {
            drawWindIcon(dc, cx, cy, lowPowerMode);
        } else if (iconKey == "MIXED") {
            drawCloudIcon(dc, cx, cy - 2, lowPowerMode);
            drawRainIcon(dc, cx - 3, cy + 4, lowPowerMode);
            drawSnowflake(dc, cx + 5, cy + 5, 3, lowPowerMode);
        } else if (iconKey == "HAZE") {
            drawHazeIcon(dc, cx, cy, lowPowerMode);
        } else {
            drawUnknownWeatherIcon(dc, cx, cy, lowPowerMode);
        }
    }

    private function drawSunIcon(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        var iconColor = lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT;

        dc.setColor(iconColor, iconColor);
        dc.fillCircle(cx, cy, 3);
        dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);

        var rays = [
            [0, -7, 0, -5],
            [0, 7, 0, 5],
            [-7, 0, -5, 0],
            [7, 0, 5, 0],
            [-5, -5, -4, -4],
            [5, -5, 4, -4],
            [-5, 5, -4, 4],
            [5, 5, 4, 4]
        ];

        for (var i = 0; i < rays.size(); i += 1) {
            dc.drawLine(cx + rays[i][0], cy + rays[i][1], cx + rays[i][2], cy + rays[i][3]);
        }
    }

    private function drawCloudIcon(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        var iconColor = lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT;

        dc.setColor(iconColor, iconColor);
        dc.fillCircle(cx - 4, cy, 3);
        dc.fillCircle(cx, cy - 2, 4);
        dc.fillCircle(cx + 5, cy, 3);
        dc.fillRoundedRectangle(cx - 8, cy, 16, 5, 2);
    }

    private function drawRainIcon(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        dc.setColor(lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - 4, cy, cx - 5, cy + 3);
        dc.drawLine(cx, cy + 1, cx - 1, cy + 4);
        dc.drawLine(cx + 4, cy, cx + 3, cy + 3);
    }

    private function drawStormBolt(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        var iconColor = lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT;

        dc.setColor(iconColor, iconColor);
        dc.fillPolygon([
            [cx - 1, cy - 1],
            [cx + 2, cy - 1],
            [cx, cy + 3],
            [cx + 3, cy + 3],
            [cx - 1, cy + 8],
            [cx, cy + 4],
            [cx - 3, cy + 4]
        ]);
    }

    private function drawSnowIcon(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        dc.setColor(lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT, Graphics.COLOR_TRANSPARENT);
        drawSnowflake(dc, cx - 3, cy, 2, lowPowerMode);
        drawSnowflake(dc, cx + 3, cy + 1, 2, lowPowerMode);
    }

    private function drawSnowflake(dc as Dc, cx as Number, cy as Number, radius as Number, lowPowerMode as Boolean) as Void {
        dc.setColor(lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - radius, cy, cx + radius, cy);
        dc.drawLine(cx, cy - radius, cx, cy + radius);
        dc.drawLine(cx - radius, cy - radius, cx + radius, cy + radius);
        dc.drawLine(cx - radius, cy + radius, cx + radius, cy - radius);
    }

    private function drawWindIcon(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        dc.setColor(lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - 7, cy - 2, cx + 5, cy - 2);
        dc.drawLine(cx - 4, cy + 2, cx + 7, cy + 2);
        dc.drawLine(cx + 5, cy - 2, cx + 7, cy - 3);
        dc.drawLine(cx + 5, cy + 2, cx + 7, cy + 1);
    }

    private function drawHazeIcon(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        dc.setColor(lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - 7, cy - 4, cx + 7, cy - 4);
        dc.drawLine(cx - 9, cy, cx + 5, cy);
        dc.drawLine(cx - 6, cy + 4, cx + 8, cy + 4);
    }

    private function drawUnknownWeatherIcon(dc as Dc, cx as Number, cy as Number, lowPowerMode as Boolean) as Void {
        dc.setColor(lowPowerMode ? COLOR_SLEEP_WEATHER_ACCENT : COLOR_WEATHER_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, 6);
        dc.drawLine(cx - 3, cy + 3, cx + 3, cy - 3);
    }

    private function getWeatherDisplay() as Array<String> {
        var conditions = Weather.getCurrentConditions();
        if (conditions == null || conditions.temperature == null) {
            return ["NO WX", "UNKNOWN"];
        }

        var temperatureText = formatTemperature(conditions.temperature as Numeric);
        var conditionText = getConditionLabel(conditions.condition);

        if (conditionText == "") {
            return [temperatureText, "UNKNOWN"];
        }

        return [temperatureText, conditionText];
    }

    private function formatTemperature(temperatureC as Numeric) as String {
        var units = System.getDeviceSettings().temperatureUnits;
        var value = temperatureC.toFloat();
        var suffix = "C";

        if (units == System.UNIT_STATUTE) {
            value = (value * 9.0 / 5.0) + 32.0;
            suffix = "F";
        }

        return Math.round(value).format("%d") + suffix;
    }

    private function getConditionLabel(condition as Number or Null) as String {
        if (condition == null) {
            return "";
        }

        if (condition == Weather.CONDITION_CLEAR || condition == Weather.CONDITION_FAIR) {
            return "CLEAR";
        } else if (condition == Weather.CONDITION_PARTLY_CLOUDY || condition == Weather.CONDITION_PARTLY_CLEAR || condition == Weather.CONDITION_MOSTLY_CLEAR || condition == Weather.CONDITION_THIN_CLOUDS) {
            return "PARTLY";
        } else if (condition == Weather.CONDITION_MOSTLY_CLOUDY || condition == Weather.CONDITION_CLOUDY) {
            return "CLOUDY";
        } else if (condition == Weather.CONDITION_RAIN || condition == Weather.CONDITION_LIGHT_RAIN || condition == Weather.CONDITION_HEAVY_RAIN || condition == Weather.CONDITION_SHOWERS || condition == Weather.CONDITION_LIGHT_SHOWERS || condition == Weather.CONDITION_HEAVY_SHOWERS || condition == Weather.CONDITION_SCATTERED_SHOWERS || condition == Weather.CONDITION_CHANCE_OF_SHOWERS || condition == Weather.CONDITION_DRIZZLE || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN) {
            return "RAIN";
        } else if (condition == Weather.CONDITION_THUNDERSTORMS || condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS || condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS) {
            return "STORM";
        } else if (condition == Weather.CONDITION_SNOW || condition == Weather.CONDITION_LIGHT_SNOW || condition == Weather.CONDITION_HEAVY_SNOW || condition == Weather.CONDITION_FLURRIES || condition == Weather.CONDITION_CHANCE_OF_SNOW || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW) {
            return "SNOW";
        } else if (condition == Weather.CONDITION_FOG || condition == Weather.CONDITION_MIST || condition == Weather.CONDITION_HAZE || condition == Weather.CONDITION_HAZY || condition == Weather.CONDITION_SMOKE || condition == Weather.CONDITION_DUST || condition == Weather.CONDITION_SAND || condition == Weather.CONDITION_SANDSTORM || condition == Weather.CONDITION_VOLCANIC_ASH) {
            return "HAZE";
        } else if (condition == Weather.CONDITION_WINDY || condition == Weather.CONDITION_SQUALL || condition == Weather.CONDITION_TROPICAL_STORM || condition == Weather.CONDITION_HURRICANE || condition == Weather.CONDITION_TORNADO) {
            return "WIND";
        } else if (condition == Weather.CONDITION_WINTRY_MIX || condition == Weather.CONDITION_RAIN_SNOW || condition == Weather.CONDITION_LIGHT_RAIN_SNOW || condition == Weather.CONDITION_HEAVY_RAIN_SNOW || condition == Weather.CONDITION_CHANCE_OF_RAIN_SNOW || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW || condition == Weather.CONDITION_ICE || condition == Weather.CONDITION_ICE_SNOW || condition == Weather.CONDITION_SLEET || condition == Weather.CONDITION_FREEZING_RAIN || condition == Weather.CONDITION_HAIL || condition == Weather.CONDITION_UNKNOWN_PRECIPITATION) {
            return "MIXED";
        }

        return "";
    }

    private function getSleepOffset(minute as Number) as Array<Number> {
        var offsets = [
            [0, 0],
            [2, 1],
            [-2, 1],
            [1, -2],
            [-1, -2]
        ];

        return offsets[minute % offsets.size()];
    }

    private function isLowPowerMode() as Boolean {
        if (!_isAwake) {
            return true;
        }

        if (System has :getDisplayMode) {
            var displayMode = System.getDisplayMode();
            return displayMode == System.DISPLAY_MODE_LOW_POWER || displayMode == System.DISPLAY_MODE_OFF;
        }

        return false;
    }
}
