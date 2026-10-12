package backend;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

/**
 * PsychCamera handles framerate-independent camera tracking (followLerp)
 * and prevents snapping/jittering at higher or variable framerates.
 */
class PsychCamera extends FlxCamera
{
	/**
	 * Separate lerp speed controls for X and Y axes.
	 * If set below 0, defaults to standard `followLerp`.
	 */
	public var followLerpX:Float = -1;
	public var followLerpY:Float = -1;

	/**
	 * Toggles exponential decay smoothing vs standard FlxMath.lerp logic.
	 */
	public var useDecaySmoothing:Bool = true;

	override public function update(elapsed:Float):Void
	{
		if (target != null)
		{
			updateFollowDelta(elapsed);
		}

		updateScroll();
		updateFlash(elapsed);
		updateFade(elapsed);

		flashSprite.filters = filtersEnabled ? filters : null;

		updateFlashSpritePosition();
		updateShake(elapsed);
	}

	public function updateFollowDelta(?elapsed:Float = 0):Void
	{
		if (target == null) return;

		// Calculate basic follow position
		if (deadzone == null)
		{
			target.getMidpoint(_point);
			_point.addPoint(targetOffset);
			_scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
		}
		else
		{
			var edge:Float;
			var targetX:Float = target.x + targetOffset.x;
			var targetY:Float = target.y + targetOffset.y;

			if (style == SCREEN_BY_SCREEN)
			{
				if (targetX >= viewRight)
				{
					_scrollTarget.x += viewWidth;
				}
				else if (targetX + target.width < viewLeft)
				{
					_scrollTarget.x -= viewWidth;
				}

				if (targetY >= viewBottom)
				{
					_scrollTarget.y += viewHeight;
				}
				else if (targetY + target.height < viewTop)
				{
					_scrollTarget.y -= viewHeight;
				}

				bindScrollPos(_scrollTarget);
			}
			else
			{
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge) _scrollTarget.x = edge;

				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge) _scrollTarget.x = edge;

				edge = targetY - deadzone.y;
				if (_scrollTarget.y > edge) _scrollTarget.y = edge;

				edge = targetY + target.height - deadzone.y - deadzone.height;
				if (_scrollTarget.y < edge) _scrollTarget.y = edge;
			}

			if ((target is FlxSprite))
			{
				if (_lastTargetPosition == null)
				{
					_lastTargetPosition = FlxPoint.get(target.x, target.y);
				}

				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

				_lastTargetPosition.set(target.x, target.y);
			}
		}

		// Calculate Lerp Multipliers per axis
		var lerpX:Float = (followLerpX >= 0) ? followLerpX : followLerp;
		var lerpY:Float = (followLerpY >= 0) ? followLerpY : followLerp;

		var multX:Float;
		var multY:Float;

		if (useDecaySmoothing)
		{
			// Delta-time independent exponential smoothing
			multX = 1 - Math.exp(-elapsed * lerpX * 60);
			multY = 1 - Math.exp(-elapsed * lerpY * 60);
		}
		else
		{
			// Standard FlxMath bound interpolation
			multX = FlxMath.bound(elapsed * lerpX * 60, 0, 1);
			multY = FlxMath.bound(elapsed * lerpY * 60, 0, 1);
		}

		// Apply scroll positioning
		scroll.x += (_scrollTarget.x - scroll.x) * multX;
		scroll.y += (_scrollTarget.y - scroll.y) * multY;
	}

	override function set_followLerp(value:Float):Float
	{
		return followLerp = value;
	}

	override public function destroy():Void
	{
		if (_lastTargetPosition != null)
		{
			_lastTargetPosition.put();
			_lastTargetPosition = null;
		}
		super.destroy();
	}
}
