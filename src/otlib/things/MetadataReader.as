/*
*  Copyright (c) 2014-2019 Object Builder <https://github.com/ottools/ObjectBuilder>
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.
*/

package otlib.things
{
    import com.mignari.errors.NotImplementedMethodError;

    import flash.filesystem.FileStream;
    import flash.utils.Endian;

    import otlib.animation.FrameDuration;
	import otlib.animation.FrameGroup;
    import otlib.sprites.Sprite;

    public class MetadataReader extends FileStream implements IMetadataReader
    {
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------

        public function MetadataReader()
        {
            endian = Endian.LITTLE_ENDIAN;
        }

        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------

        //--------------------------------------
        // Public
        //--------------------------------------

        public function readSignature():uint
        {
            position = MetadataFilePosition.SIGNATURE;
            return readUnsignedInt();
        }

        public function readItemsCount():uint
        {
            position = MetadataFilePosition.ITEMS_COUNT;
            return readUnsignedShort();
        }

        public function readOutfitsCount():uint
        {
            position = MetadataFilePosition.OUTFITS_COUNT;
            return readUnsignedShort();
        }

        public function readEffectsCount():uint
        {
            position = MetadataFilePosition.EFFECTS_COUNT;
            return readUnsignedShort();
        }

        public function readMissilesCount():uint
        {
            position = MetadataFilePosition.MISSILES_COUNT;
            return readUnsignedShort();
        }

        public function readProperties(type:ThingType):Boolean
        {
            throw new NotImplementedMethodError();
        }

        public function readTexturePatterns(type:ThingType, extended:Boolean, frameDurations:Boolean, frameGroups:Boolean):Boolean
        {
            var groupCount:uint = 1;
			if(frameGroups && type.category == ThingCategory.OUTFIT) {
				groupCount = readUnsignedByte();
			}

            var i:uint;
            var groupType:uint;
			var frameGroup:FrameGroup;
            for(groupType = 0; groupType < groupCount; groupType++) 
            {
			    if(frameGroups && type.category == ThingCategory.OUTFIT)
					readUnsignedByte();

                frameGroup = new FrameGroup();
                frameGroup.width = readUnsignedByte();
                frameGroup.height = readUnsignedByte();

                if (frameGroup.width > 1 || frameGroup.height > 1)
                    frameGroup.exactSize = readUnsignedByte();
                else
                    frameGroup.exactSize = Sprite.DEFAULT_SIZE;

                frameGroup.layers = readUnsignedByte();
                frameGroup.patternX = readUnsignedByte();
                frameGroup.patternY = readUnsignedByte();
                frameGroup.patternZ = readUnsignedByte();
                frameGroup.frames = readUnsignedByte();
                if (frameGroup.frames > 1) {
                    frameGroup.isAnimation = true;
                    frameGroup.frameDurations = new Vector.<FrameDuration>(frameGroup.frames, true);

                    if (frameDurations) {
                        frameGroup.animationMode = readUnsignedByte();
                        frameGroup.loopCount = readInt();
                        frameGroup.startFrame = readByte();

                        for (i = 0; i < frameGroup.frames; i++)
                        {
                            var minimum:uint = readUnsignedInt();
                            var maximum:uint = readUnsignedInt();
                            frameGroup.frameDurations[i] = new FrameDuration(minimum, maximum);
                        }
                    } else {
                        var duration:uint = FrameDuration.getDefaultDuration(type.category);
                        for (i = 0; i < frameGroup.frames; i++)
                            frameGroup.frameDurations[i] = new FrameDuration(duration, duration);
                    }
                }

                var totalSprites:uint = frameGroup.getTotalSprites();
                if (totalSprites > 4096)
                    throw new Error("A thing type has more than 4096 sprites.");

                frameGroup.spriteIndex = new Vector.<uint>(totalSprites);
                for (i = 0; i < totalSprites; i++) {
                    if (extended)
                        frameGroup.spriteIndex[i] = readUnsignedInt();
                    else
                        frameGroup.spriteIndex[i] = readUnsignedShort();
                }

                type.setFrameGroup(groupType, frameGroup);
            }

            return true;
        }
    }
}
