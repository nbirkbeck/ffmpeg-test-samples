function gen_test_samples()
for bit_depth=[8,10],
  mx = 2^bit_depth - 1;
  w = 32 * 16;
  mid = ones(32, w) * 2^(bit_depth-1);
  X = linspace(0, mx, 32);
  X = repmat(X, [16, 1]);
  X = X(:)';
  
  X = repmat(X, [32, 1]);
  Y = [X; mid; mid];
  U = [mid; X; mid];
  V = [mid; mid; X];
  
  imagesc(X);
  write_yuv444_frame(sprintf('/tmp/yuv444p%d', bit_depth), cat(3, Y, U, V),...
                     bit_depth);

  suffix = ''
  pix_fmt = 'yuvj444p'
  if bit_depth ~= 8
    suffix = '-10bit';  % Assumes you have a version of
                        % ffmpeg_10bit on your path compiled with
                        % 10-bit x264 encode capability.
    pix_fmt = sprintf('yuv444p%dle', bit_depth);
  end
  system(sprintf(['ffmpeg%s -f ' ...
                  'rawvideo -pix_fmt %s -video_size 512x96  ' ...
                  '-i /tmp/yuv444p%d -color_range 2 -color_trc 1 -colorspace 1 ' ...
                  '-color_primaries 1 -vcodec libx264 -y -crf 1' ...
                  ' /tmp/yuv444p%d.mp4'], ...
                 suffix, pix_fmt, bit_depth, bit_depth));
  system(sprintf(['ffmpeg%s -f ' ...
                  'rawvideo -pix_fmt %s -video_size 512x96  ' ...
                  '-i /tmp/yuv444p%d -color_range 2 -color_trc 1 -colorspace 1 ' ...
                  '-color_primaries 1 -vcodec rawvideo -y /tmp/yuv444p%d.nut'], ...
                 suffix, pix_fmt, bit_depth, bit_depth));
end

function write_yuv444_frame(filename, data, bit_depth)
cast = @(x)(uint16(x));
type = 'uint16';
if bit_depth == 8,
  cast = @(x)(uint8(x));
  type = 'uint8';
end
f = fopen(filename, 'w');
for i=1:3,
  fwrite(f, cast(data(:, :, i)'), type);
end
fclose(f);
