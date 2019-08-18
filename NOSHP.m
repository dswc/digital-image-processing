
function ContrastEnhancementV3()
close all; clear all; clc;

Img = imread( 'g1.bmp' );
mask = imread( 'ed1.bmp' );

img1 = zeros( size( Img ));
img2 = zeros( size( Img ));

[ m, n ] = size( Img );


Br = floor( m / 16 );
Bc = floor( n / 16 );

for row = 1 : Br : m
    for col = 1 : Bc : n
        IndexRow = row;
        IndexCol = col;
        if ( (IndexRow + 2*Br - 1 <= m) && (IndexCol + 2*Bc - 1 <= n) ) && ( sum(sum( mask( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 ) ) ) > 0 )
            % =========================================================================
            SubBlockA = Img( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 );
            SubMaskA = mask( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 );

            IndexRow = row;
            IndexCol = col + Bc;
            SubBlockB = Img( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 );
            SubMaskB = mask( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 );
     
            IndexRow = row + Br;
            IndexCol = col;
            SubBlockC = Img( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 );
            SubMaskC = mask( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 );
      
            IndexRow = row + Br;
            IndexCol = col + Bc;
            SubBlockD = Img( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 );
            SubMaskD = mask( IndexRow : IndexRow +Br-1, IndexCol : IndexCol + Bc-1 );
            % =========================================================================
            [SubBlockRow, SubBlockCol] = size( SubBlockA );
            
            % histogram
            X_A = myImhist( SubBlockA, SubMaskA );
            X_B = myImhist( SubBlockB, SubMaskB );
            X_C = myImhist( SubBlockC, SubMaskC );
            X_D = myImhist( SubBlockD, SubMaskD );

            pdf_A = X_A / sum(X_A);
            pdf_B = X_B / sum(X_B);
            pdf_C = X_C / sum(X_C);
            pdf_D = X_D / sum(X_D);
            
            % 如果ＰＤＦ＞０　則Ｆｌａg+
            flag_A = pdf_A > 0;
            flag_B = pdf_B > 0;
            flag_C = pdf_C > 0;
            flag_D = pdf_D > 0;

            cdf_A = zeros( size( pdf_A ) );
            cdf_B = zeros( size( pdf_B ) );
            cdf_C = zeros( size( pdf_C ) );
            cdf_D = zeros( size( pdf_D ) );
            
            for ii = 1 : length(pdf_A)
              cdf_A( ii ) = sum( flag_A( 1 : ii ) );
              cdf_B( ii ) = sum( flag_B( 1 : ii ) );
              cdf_C( ii ) = sum( flag_C( 1 : ii ) );
              cdf_D( ii ) = sum( flag_D( 1 : ii ) );
            end

            % 論文的 Tb 和 Tc 順序寫錯.
            tmp = zeros( size( SubBlockA ) );
            for x = 1 : SubBlockRow
                for y = 1 : SubBlockCol
                   tmp(x,y) = ( mappingFun( cdf_A, SubBlockA(x,y) ) * (SubBlockRow +1 -x) * (SubBlockCol +1 -y) ...
                              + mappingFun( cdf_C, SubBlockA(x,y) ) * x * (SubBlockCol +1 -y) ...
                              + mappingFun( cdf_B, SubBlockA(x,y) ) * y * (SubBlockRow +1 -x) ...
                              + mappingFun( cdf_D, SubBlockA(x,y) ) * x * y ) ...
                              / ( (SubBlockRow +1) * (SubBlockCol +1) );
                end
            end
            
            % mapping funciton.
            T_A = (cdf_A / sum( flag_A ) ) * 255;

            % 使用 mapping funciton 更新像素值.
            SubBlockA = double( SubBlockA );
            for x = 1 : SubBlockRow
                for y = 1 : SubBlockCol
                    SubBlockA(x, y) = T_A( SubBlockA( x, y ) +1 );

                end
            end
            
            img1( row : row+Br-1 , col : col+Bc-1 ) = SubBlockA;
            img2( row : row+Br-1 , col : col+Bc-1 ) = tmp;
        end
    end
end

% 複製最下一列
for x = row  : m
    for y = 1 : n
        img1(x, y) = double(Img(x, y));    
        img2(x, y) = double(Img(x, y));
    end
end

% 複製最右一行
for x = 1  : m
    for y = col - Bc : n
        img1(x, y) = double(Img(x, y));    
        img2(x, y) = double(Img(x, y));
    end
end

figure; imshow( uint8(img1) );

figure; imshow( uint8(img2) );

% =========================================================================
function Out = myImhist( Img, Mask )
Statistic = zeros( 256, 1 );
[ Row, Col ] = size( Img );
for r = 1 : Row
    for c = 1 : Col
        if ( Mask( r, c ) == 1 )
            Statistic( Img( r, c) + 1 ) = Statistic( Img( r, c) + 1 ) + 1 ;
        end
    end
end
Out = Statistic;
% =========================================================================

function Out = mappingFun( Cdf, GrayLevel )
% 避免分母為 0，程式會NAN.
if ( Cdf( 256 ) == 0 )
    Denominator = 1 ;
else
    Denominator = Cdf( 256 );
end
Out = ( Cdf(GrayLevel + 1) / Denominator ) * 255;
% =========================================================================