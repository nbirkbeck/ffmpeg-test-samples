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
  
  suffix = '_pc'
  ffmpeg_suffix = ''
  pix_fmt = 'yuvj444p'
  if bit_depth ~= 8
    ffmpeg_suffix = '-10bit';  % Assumes you have a version of
                        % ffmpeg_10bit on your path compiled with
                        % 10-bit x264 encode capability.
    pix_fmt = sprintf('yuv444p%dle', bit_depth);
    suffix = sprintf('%d_pc', bit_depth);
  end
  
  imagesc(X);
  write_yuv444_frame(sprintf('/tmp/color_gradient_yuv444p%s', suffix), cat(3, Y, U, V),...
                     bit_depth);

  system(sprintf(['ffmpeg%s -f ' ...
                  'rawvideo -pix_fmt %s -video_size 512x96  ' ...
                  '-i /tmp/color_gradient_yuv444p%s -color_range 2 -color_trc 1 -colorspace 1 ' ...
                  '-color_primaries 1 -vcodec libx264 -y -crf 1' ...
                  ' /tmp/color_gradient_yuv444p%s.mp4'], ...
                 ffmpeg_suffix, pix_fmt, suffix, suffix));
  system(sprintf(['ffmpeg%s -f ' ...
                  'rawvideo -pix_fmt %s -video_size 512x96  ' ...
                  '-i /tmp/color_gradient_yuv444p%s -color_range 2 -color_trc 1 -colorspace 1 ' ...
                  '-color_primaries 1 -vcodec rawvideo -y /tmp/color_gradient_yuv444p%s.nut'], ...
                 ffmpeg_suffix, pix_fmt, suffix, suffix));
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
