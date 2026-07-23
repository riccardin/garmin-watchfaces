import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SpiderManFaceView extends WatchUi.WatchFace {
    private const COLOR_BG = 0x000000;
    private const COLOR_TEXT = 0xF0F0F0;
    private const COLOR_TEXT_DIM = 0xB0B0B0;
    private const COLOR_SLEEP_TEXT = 0x888888;
    private const COLOR_SLEEP_TEXT_DIM = 0x575757;
    private const COLOR_RED = 0xF11414;
    private const COLOR_RED_SOFT = 0xA20A0A;
    private const COLOR_SLEEP_RED = 0x7D1818;
    private const COLOR_PLATFORM_MASK = 0x02101A;
    private const FACE_SIZE = 416;
    private const HALF_FACE_SIZE = 208;
    private const STEPS_RING_OFFSET_X = 91;
    private const STEPS_RING_OFFSET_Y = -98;
    private const STEPS_VALUE_OFFSET_X = 91;
    private const STEPS_VALUE_OFFSET_Y = -85;
    private const STRESS_RING_OFFSET_X = 108;
    private const STRESS_RING_OFFSET_Y = -24;
    private const STRESS_VALUE_OFFSET_X = 112;
    private const STRESS_VALUE_OFFSET_Y = -12;
    private const HEART_RING_OFFSET_X = 101;
    private const HEART_RING_OFFSET_Y = 50;
    private const HEART_VALUE_OFFSET_X = 101;
    private const HEART_VALUE_OFFSET_Y = 62;
    private const STRESS_MAX_SCORE = 100.0;
    private const HEART_PROGRESS_MAX = 200.0;

    private var _isAwake as Boolean = true;
    private var _faceBitmap as Graphics.BitmapReference or WatchUi.BitmapResource or Null = null;

    function initialize() {
        WatchFace.initialize();
        _faceBitmap = Application.loadResource(Rez.Drawables.SpiderManFaceReal) as Graphics.BitmapReference or WatchUi.BitmapResource;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
        _isAwake = true;
    }

    function onUpdate(dc as Dc) as Void {
        drawFace(dc, isLowPowerMode());
    }

    function onPartialUpdate(dc as Dc) as Void {
        drawFace(dc, isLowPowerMode());
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

    private function drawFace(dc as Dc, lowPowerMode as Boolean) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var clockTime = System.getClockTime();
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var offset = lowPowerMode ? getSleepOffset(clockTime.min) : [0, 0];
        var originX = ((width - FACE_SIZE) / 2) + offset[0];
        var originY = ((height - FACE_SIZE) / 2) + offset[1];
        var cx = originX + HALF_FACE_SIZE;
        var cy = originY + HALF_FACE_SIZE;

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.clear();

        if (_faceBitmap != null) {
            dc.drawBitmap(originX, originY, _faceBitmap);
        }

        drawStepsProgressRing(dc, cx + STEPS_RING_OFFSET_X, cy + STEPS_RING_OFFSET_Y, getStepsProgressRatio(), lowPowerMode);
        drawStressProgressRing(dc, cx + STRESS_RING_OFFSET_X, cy + STRESS_RING_OFFSET_Y, getStressProgressRatio(), lowPowerMode);
        drawHeartProgressRing(dc, cx + HEART_RING_OFFSET_X, cy + HEART_RING_OFFSET_Y, getHeartProgressRatio(), lowPowerMode);

        if (lowPowerMode) {
            drawLowPowerDimmingOverlay(dc, originX, originY);
        }

        eraseLeftInfo(dc, cx, cy);
        eraseStepsValueArea(dc, cx + STEPS_RING_OFFSET_X, cy + STEPS_RING_OFFSET_Y);
        eraseStressValueArea(dc, cx + STRESS_RING_OFFSET_X, cy + STRESS_RING_OFFSET_Y);
        eraseHeartValueArea(dc, cx + HEART_RING_OFFSET_X, cy + HEART_RING_OFFSET_Y);
        eraseTimeDisplay(dc, cx, cy + 82);
        drawLeftInfo(dc, cx, cy, getWeekdayLabel(today.day_of_week as Number), today.day as Number, getBatteryPercent(), lowPowerMode);
        drawComplicationValue(dc, cx + STEPS_VALUE_OFFSET_X, cy + STEPS_VALUE_OFFSET_Y, formatStepsCompact(getStepsValue()), lowPowerMode, "steps");
        drawComplicationValue(dc, cx + STRESS_VALUE_OFFSET_X, cy + STRESS_VALUE_OFFSET_Y, formatMetricValue(getStressValue()), lowPowerMode, "stress");
        drawComplicationValue(dc, cx + HEART_VALUE_OFFSET_X, cy + HEART_VALUE_OFFSET_Y, formatMetricValue(getHeartRateValue()), lowPowerMode, "heart");
        drawTimeDisplay(dc, cx, cy + 82, clockTime, lowPowerMode);
    }

    private function drawLowPowerDimmingOverlay(dc as Dc, originX as Number, originY as Number) as Void {
        dc.setColor(COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // A sparse black grid dims the bitmap without replacing the artwork,
        // helping the face stay visible in always-on mode with lower intensity.
        for (var y = originY; y < originY + FACE_SIZE; y += 4) {
            dc.drawLine(originX, y, originX + FACE_SIZE, y);
        }

        for (var x = originX + 1; x < originX + FACE_SIZE; x += 4) {
            dc.drawLine(x, originY, x, originY + FACE_SIZE);
        }
    }

    private function drawStepsProgressRing(dc as Dc, centerX as Number, centerY as Number, progressRatio as Float, lowPowerMode as Boolean) as Void {
        drawProgressRing(dc, centerX, centerY, progressRatio, lowPowerMode);
        drawStepsIcon(dc, centerX, centerY - 10, lowPowerMode);
    }

    private function drawStressProgressRing(dc as Dc, centerX as Number, centerY as Number, progressRatio as Float, lowPowerMode as Boolean) as Void {
        drawProgressRing(dc, centerX, centerY, progressRatio, lowPowerMode);
        drawStressIcon(dc, centerX, centerY - 7, lowPowerMode);
    }

    private function drawHeartProgressRing(dc as Dc, centerX as Number, centerY as Number, progressRatio as Float, lowPowerMode as Boolean) as Void {
        drawProgressRing(dc, centerX, centerY, progressRatio, lowPowerMode);
        drawHeartIcon(dc, centerX, centerY - 6, lowPowerMode);
    }

    private function drawProgressRing(dc as Dc, centerX as Number, centerY as Number, progressRatio as Float, lowPowerMode as Boolean) as Void {
        var rimColor = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;
        var trackColor = lowPowerMode ? 0x464646 : 0x8A8A8A;
        var progressColor = lowPowerMode ? COLOR_SLEEP_RED : COLOR_RED;
        var clampedProgress = progressRatio;

        if (clampedProgress < 0.0) {
            clampedProgress = 0.0;
        } else if (clampedProgress > 1.0) {
            clampedProgress = 1.0;
        }

        dc.setColor(rimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(centerX, centerY, 37);
        dc.drawCircle(centerX, centerY, 35);

        drawSegmentedRing(dc, centerX, centerY, 31, 4, -120.0, 300.0, 24, trackColor);
        drawSegmentedRing(dc, centerX, centerY, 31, 4, -120.0, 300.0 * clampedProgress, 24, progressColor);

        dc.setColor(COLOR_BG, COLOR_BG);
        dc.fillCircle(centerX, centerY, 25);
    }

    private function drawSegmentedRing(dc as Dc, centerX as Number, centerY as Number, radius as Number, penWidth as Number, startDegrees as Float, sweepDegrees as Float, segmentCount as Number, color as Number) as Void {
        if (sweepDegrees <= 0.0) {
            return;
        }

        var gapDegrees = 3.0;
        var segmentSweep = sweepDegrees / segmentCount;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(penWidth);

        for (var i = 0; i < segmentCount; i += 1) {
            var segmentStart = startDegrees + (segmentSweep * i) + (gapDegrees / 2.0);
            var segmentEnd = startDegrees + (segmentSweep * (i + 1)) - (gapDegrees / 2.0);

            if (segmentEnd <= segmentStart) {
                continue;
            }

            var startPoint = polarPoint(centerX, centerY, radius, segmentStart);
            var endPoint = polarPoint(centerX, centerY, radius, segmentEnd);
            dc.drawLine(startPoint[0], startPoint[1], endPoint[0], endPoint[1]);
        }

        dc.setPenWidth(1);
    }

    private function drawStepsIcon(dc as Dc, centerX as Number, centerY as Number, lowPowerMode as Boolean) as Void {
        var iconColor = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;
        dc.setColor(iconColor, iconColor);

        dc.fillCircle(centerX - 7, centerY, 4);
        dc.fillCircle(centerX - 12, centerY - 6, 2);
        dc.fillCircle(centerX - 8, centerY - 10, 2);
        dc.fillCircle(centerX - 4, centerY - 12, 2);

        dc.fillCircle(centerX + 8, centerY - 2, 4);
        dc.fillCircle(centerX + 3, centerY - 8, 2);
        dc.fillCircle(centerX + 7, centerY - 12, 2);
        dc.fillCircle(centerX + 11, centerY - 14, 2);
    }

    private function drawStressIcon(dc as Dc, centerX as Number, centerY as Number, lowPowerMode as Boolean) as Void {
        var iconColor = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;
        dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(centerX, centerY - 6, 3);
        dc.drawLine(centerX, centerY - 2, centerX, centerY + 6);
        dc.drawLine(centerX, centerY + 1, centerX - 6, centerY - 3);
        dc.drawLine(centerX, centerY + 1, centerX + 6, centerY - 3);
        dc.drawLine(centerX, centerY + 6, centerX - 5, centerY + 12);
        dc.drawLine(centerX, centerY + 6, centerX + 5, centerY + 12);
        dc.drawLine(centerX - 10, centerY - 10, centerX - 7, centerY - 13);
        dc.drawLine(centerX + 7, centerY - 13, centerX + 10, centerY - 10);
        dc.setPenWidth(1);
    }

    private function drawHeartIcon(dc as Dc, centerX as Number, centerY as Number, lowPowerMode as Boolean) as Void {
        var iconColor = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;
        dc.setColor(iconColor, iconColor);
        dc.fillCircle(centerX - 5, centerY - 2, 5);
        dc.fillCircle(centerX + 5, centerY - 2, 5);
        dc.fillPolygon([
            makePoint(centerX - 10, centerY - 1),
            makePoint(centerX + 10, centerY - 1),
            makePoint(centerX, centerY + 12)
        ]);
    }

    private function eraseLeftInfo(dc as Dc, cx as Number, cy as Number) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.fillRoundedRectangle(cx - 184, cy - 10, 130, 84, 8);
    }

    private function drawLeftInfo(dc as Dc, cx as Number, cy as Number, weekday as String, dayValue as Number, battery as Number, lowPowerMode as Boolean) as Void {
        var textColor = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;
        var dimColor = lowPowerMode ? COLOR_SLEEP_TEXT_DIM : COLOR_TEXT_DIM;
        var leftX = cx - 175;
        var dateY = cy + 3;
        var batteryX = leftX + 8;
        var batteryY = cy + 52;

        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, dateY, Graphics.FONT_XTINY, weekday + " " + dayValue.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawBatteryIcon(dc, batteryX, batteryY, battery, lowPowerMode);
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(batteryX + 26, batteryY, Graphics.FONT_XTINY, battery.format("%d") + "%", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawBatteryIcon(dc as Dc, x as Number, y as Number, battery as Number, lowPowerMode as Boolean) as Void {
        var outlineColor = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;
        var fillColor = lowPowerMode ? COLOR_SLEEP_TEXT_DIM : COLOR_TEXT_DIM;
        var fillWidth = ((battery * 16) / 100).toNumber();

        dc.setColor(outlineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, y - 6, 20, 12, 2);
        dc.fillRoundedRectangle(x + 20, y - 2, 3, 4, 1);
        dc.setColor(fillColor, fillColor);
        dc.fillRoundedRectangle(x + 2, y - 4, fillWidth, 8, 1);
    }

    private function drawComplicationValue(dc as Dc, x as Number, y as Number, label as String, lowPowerMode as Boolean, kind as String) as Void {
        var textColor = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;
        var suffixColor = lowPowerMode ? COLOR_SLEEP_TEXT_DIM : COLOR_TEXT_DIM;
        var labelLength = label.length();
        var valueY = y + 2;
        var valueFont = Graphics.FONT_XTINY;

        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        if (kind == "steps") {
            valueY = y + 6;
        } else if (kind == "stress") {
            valueY = y + 7;
        } else if (kind == "heart") {
            valueY = y + 10;
        }

        if (kind == "steps" && labelLength > 1) {
            var suffix = label.substring(labelLength - 1, labelLength) as String;
            if (suffix == "k") {
                var baseText = label.substring(0, labelLength - 1) as String;
                dc.drawText(x - 3, y + 6, valueFont, baseText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(suffixColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x + 5, y + 7, Graphics.FONT_XTINY, "k", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                return;
            }
        }

        dc.drawText(x, valueY, valueFont, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function eraseComplicationRingCenter(dc as Dc, x as Number, y as Number, radius as Number) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.fillCircle(x, y, radius);
    }

    private function eraseStepsValueArea(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.fillRoundedRectangle(x - 20, y + 3, 40, 18, 6);
    }

    private function eraseStressValueArea(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.fillRoundedRectangle(x - 14, y + 11, 28, 20, 6);
    }

    private function eraseHeartValueArea(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(COLOR_BG, COLOR_BG);
        dc.fillRoundedRectangle(x - 15, y + 11, 30, 20, 6);
    }

    private function drawTimeDisplay(dc as Dc, cx as Number, cy as Number, clockTime as ClockTime, lowPowerMode as Boolean) as Void {
        var hourValue = clockTime.hour % 12;
        if (hourValue == 0) {
            hourValue = 12;
        }

        var hourText = hourValue.format("%02d");
        var minuteText = clockTime.min.format("%02d");
        var leftOutline = lowPowerMode ? COLOR_SLEEP_RED : COLOR_RED;
        var rightOutline = lowPowerMode ? COLOR_SLEEP_RED : COLOR_RED;
        var rightFill = lowPowerMode ? COLOR_SLEEP_TEXT : COLOR_TEXT;
        var rightShadow = lowPowerMode ? COLOR_SLEEP_TEXT_DIM : COLOR_RED_SOFT;
        var digitY = cy;
        var timeCx = cx - 50;

        drawHourDigit(dc, timeCx - 100, digitY + 4, hourText.substring(0, 1) as String, leftOutline, COLOR_BG, COLOR_BG, true);
        drawHourDigit(dc, timeCx - 50, digitY + 4, hourText.substring(1, 2) as String, leftOutline, COLOR_BG, COLOR_BG, true);
        drawHourDigit(dc, timeCx, digitY, minuteText.substring(0, 1) as String, rightOutline, rightFill, rightShadow, false);
        drawHourDigit(dc, timeCx + 50, digitY, minuteText.substring(1, 2) as String, rightOutline, rightFill, rightShadow, false);
    }

    private function eraseTimeDisplay(dc as Dc, cx as Number, cy as Number) as Void {
        var timeCx = cx - 50;
        dc.setColor(COLOR_PLATFORM_MASK, COLOR_PLATFORM_MASK);
        dc.fillRoundedRectangle(timeCx - 114, cy + 30, 228, 102, 18);
        maskHourDigit(dc, timeCx - 100, cy + 4, "8");
        maskHourDigit(dc, timeCx - 50, cy + 4, "8");
        maskHourDigit(dc, timeCx, cy, "8");
        maskHourDigit(dc, timeCx + 50, cy, "8");
    }

    private function drawHourDigit(dc as Dc, x as Number, y as Number, digit as String, outlineColor as Number, fillColor as Number, shadowColor as Number, hollowCenter as Boolean) as Void {
        drawDigitWithMetrics(dc, x, y, digit, outlineColor, fillColor, shadowColor, hollowCenter, 45, 78, 8, 4, 0.14);
    }

    private function maskHourDigit(dc as Dc, x as Number, y as Number, digit as String) as Void {
        drawDigitWithMetrics(dc, x - 4, y - 4, digit, COLOR_PLATFORM_MASK, COLOR_PLATFORM_MASK, COLOR_PLATFORM_MASK, false, 54, 92, 13, 9, 0.14);
    }

    private function drawDigitWithMetrics(dc as Dc, x as Number, y as Number, digit as String, outlineColor as Number, fillColor as Number, shadowColor as Number, hollowCenter as Boolean, width as Number, height as Number, outerThickness as Number, innerThickness as Number, shear as Float) as Void {
        var segments = getDigitSegments(digit);
        var shadowOffset = (shadowColor == COLOR_BG) ? 0 : 3;

        if (shadowOffset > 0) {
            for (var i = 0; i < segments.size(); i += 1) {
                drawSegment(dc, x + shadowOffset, y + shadowOffset, segments[i], width, height, shear, outerThickness, shadowColor);
            }
        }

        for (var j = 0; j < segments.size(); j += 1) {
            drawSegment(dc, x, y, segments[j], width, height, shear, outerThickness, outlineColor);
        }

        var centerColor = hollowCenter ? COLOR_BG : fillColor;
        for (var k = 0; k < segments.size(); k += 1) {
            drawSegment(dc, x, y, segments[k], width, height, shear, innerThickness, centerColor);
        }
    }

    private function drawSegment(dc as Dc, x as Number, y as Number, segment as String, width as Number, height as Number, shear as Float, thickness as Number, color as Number) as Void {
        var right = width;
        var middle = height / 2;
        var bottom = height;
        var inset = 10;
        var poly = [] as Array<[Numeric, Numeric]>;

        if (segment.equals("a")) {
            poly = makeShearedQuad(x + inset, y, x + right - inset, y + thickness, shear);
        } else if (segment.equals("d")) {
            poly = makeShearedQuad(x + inset, y + bottom - thickness, x + right - inset, y + bottom, shear);
        } else if (segment.equals("g")) {
            poly = makeShearedQuad(x + inset + 4, y + middle - (thickness / 2), x + right - inset - 4, y + middle + (thickness / 2), shear);
        } else if (segment.equals("f")) {
            poly = makeShearedQuad(x, y + thickness, x + thickness, y + middle - 3, shear);
        } else if (segment.equals("b")) {
            poly = makeShearedQuad(x + right - thickness, y + thickness, x + right, y + middle - 3, shear);
        } else if (segment.equals("e")) {
            poly = makeShearedQuad(x + 4, y + middle + 3, x + thickness + 4, y + bottom - thickness, shear);
        } else if (segment.equals("c")) {
            poly = makeShearedQuad(x + right - thickness - 4, y + middle + 3, x + right - 4, y + bottom - thickness, shear);
        } else if (segment.equals("1l")) {
            poly = makeShearedQuad(x + 14, y + 14, x + 24, y + bottom, shear);
        } else if (segment.equals("1r")) {
            poly = makeShearedQuad(x + 24, y + 6, x + 36, y + bottom - 2, shear);
        }

        if (poly.size() > 0) {
            dc.setColor(color, color);
            dc.fillPolygon(poly);
        }
    }

    private function makeShearedQuad(left as Numeric, top as Numeric, right as Numeric, bottom as Numeric, shear as Float) as Array<[Numeric, Numeric]> {
        return [
            makePoint(left + (top * shear), top),
            makePoint(right + (top * shear), top),
            makePoint(right + (bottom * shear), bottom),
            makePoint(left + (bottom * shear), bottom)
        ];
    }

    private function getDigitSegments(digit as String) as Array<String> {
        if (digit.equals("0")) {
            return ["a", "b", "c", "d", "e", "f"];
        } else if (digit.equals("1")) {
            return ["1l", "1r"];
        } else if (digit.equals("2")) {
            return ["a", "b", "g", "e", "d"];
        } else if (digit.equals("3")) {
            return ["a", "b", "g", "c", "d"];
        } else if (digit.equals("4")) {
            return ["f", "g", "b", "c"];
        } else if (digit.equals("5")) {
            return ["a", "f", "g", "c", "d"];
        } else if (digit.equals("6")) {
            return ["a", "f", "g", "c", "d", "e"];
        } else if (digit.equals("7")) {
            return ["a", "b", "c"];
        } else if (digit.equals("8")) {
            return ["a", "b", "c", "d", "e", "f", "g"];
        }

        return ["a", "b", "c", "d", "f", "g"];
    }

    private function getBatteryPercent() as Number {
        return System.getSystemStats().battery as Number;
    }

    private function getStepsValue() as Number or Null {
        var info = ActivityMonitor.getInfo();
        if (info.steps != null) {
            return info.steps as Number;
        }

        return null;
    }

    private function getStepGoalValue() as Number or Null {
        var info = ActivityMonitor.getInfo();
        if (info.stepGoal != null) {
            return info.stepGoal as Number;
        }

        return null;
    }

    private function getStepsProgressRatio() as Float {
        var steps = getStepsValue();
        var goal = getStepGoalValue();

        if (steps == null || goal == null || goal <= 0) {
            return 0.0;
        }

        return steps.toFloat() / goal.toFloat();
    }

    private function getStressValue() as Number or Null {
        var info = ActivityMonitor.getInfo();
        if (info.stressScore != null) {
            return info.stressScore as Number;
        }

        return null;
    }

    private function getStressProgressRatio() as Float {
        var stress = getStressValue();
        if (stress == null) {
            return 0.0;
        }

        return stress.toFloat() / STRESS_MAX_SCORE;
    }

    private function getHeartRateValue() as Number or Null {
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null && activityInfo.currentHeartRate != null) {
            return activityInfo.currentHeartRate as Number;
        }

        if (ActivityMonitor has :getHeartRateHistory) {
            var iterator = ActivityMonitor.getHeartRateHistory(1, true);
            var sample = iterator.next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate as Number;
            }
        }

        return null;
    }

    private function getHeartProgressRatio() as Float {
        var heartRate = getHeartRateValue();
        if (heartRate == null) {
            return 0.0;
        }

        return heartRate.toFloat() / HEART_PROGRESS_MAX;
    }

    private function formatStepsCompact(steps as Number or Null) as String {
        if (steps == null) {
            return "--";
        }

        if (steps >= 10000) {
            return ((steps / 1000).toNumber()).format("%d") + "k";
        }

        if (steps >= 1000) {
            var compactValue = ((steps.toFloat() / 1000.0) * 10.0).toNumber();
            var whole = compactValue / 10;
            var fractional = compactValue % 10;

            if (fractional == 0) {
                return whole.format("%d") + "k";
            }

            return whole.format("%d") + "." + fractional.format("%d") + "k";
        }

        return steps.format("%d");
    }

    private function formatMetricValue(value as Number or Null) as String {
        if (value == null) {
            return "--";
        }

        return value.format("%d");
    }

    private function getWeekdayLabel(dayOfWeek as Number) as String {
        var labels = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        if (dayOfWeek < 0 || dayOfWeek >= labels.size()) {
            return "DAY";
        }

        return labels[dayOfWeek];
    }

    private function isLowPowerMode() as Boolean {
        return !_isAwake;
    }

    private function getSleepOffset(minute as Number) as Array<Number> {
        var phase = minute % 4;
        if (phase == 0) {
            return [-2, -1];
        } else if (phase == 1) {
            return [2, -1];
        } else if (phase == 2) {
            return [1, 2];
        }

        return [-1, 2];
    }

    private function makePoint(x as Numeric, y as Numeric) as [Numeric, Numeric] {
        return [x.toNumber(), y.toNumber()];
    }

    private function polarPoint(cx as Numeric, cy as Numeric, radius as Numeric, degrees as Float) as [Numeric, Numeric] {
        var radians = degrees * Math.PI / 180.0;
        return makePoint(cx + (Math.cos(radians) * radius), cy + (Math.sin(radians) * radius));
    }
}
