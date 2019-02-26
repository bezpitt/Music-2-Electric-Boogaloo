function [soundSample]= create_chord(instrument,notes, constants)
    switch instrument.temperament
            case {'just','Just'}
                ratio = [1 16/15 9/8 6/5 5/4 4/3 45/32 3/2 8/5 5/3 9/5 15/8];
                bigratio = [ratio/16 ratio/8 ratio/4 ratio/2 ratio 2*ratio 4*ratio 8*ratio];%A0 to G#7
            case {'equal','Equal'}
                list = 0:11;
                ratio = (2^(1/12)).^list;
                bigratio = [ratio/16 ratio/8 ratio/4 ratio/2 ratio 2*ratio 4*ratio 8*ratio];%A0 to G#7
            otherwise
                error('Inproper temperament specified')
    end
        for k = 1:3
            [notechooser,octavechooser] = split(notes{k}.note, ["0", "1", "2", "3", "4", "5", "6", "7"]);
            switch notechooser{1,1}
                case {'A'}
                    index = 1 + 12*str2double(octavechooser);
                case {'A#', 'Bb'}
                    index = 2 + 12*str2double(octavechooser);
                case {'B'}
                    index = 3 + 12*str2double(octavechooser);
                case {'C'}
                    index = 4 + 12*(str2double(octavechooser)-1);
                case {'C#', 'Db'}
                    index = 5 + 12*(str2double(octavechooser)-1);
                case {'D'}
                    index = 6 + 12*(str2double(octavechooser)-1);
                case {'D#', 'Eb'}
                    index = 7 + 12*(str2double(octavechooser)-1);
                case {'E'}
                    index = 8 + 12*(str2double(octavechooser)-1);
                case {'F'}
                    index = 9 + 12*(str2double(octavechooser)-1);
                case {'F#', 'Gb'}
                    index = 10 + 12*(str2double(octavechooser)-1);
                case {'G'}
                    index = 11 + 12*(str2double(octavechooser)-1);
                case {'G#', 'Ab'}
                    index = 12 + 12*(str2double(octavechooser)-1);
                otherwise
                    error("Invalid root note");
            end
            startnote = 440 * bigratio(index);
            switch instrument.sound
                case {'Additive'}
                    %Bell from book
                    A = 1;
                    constants.durationScale = 10;
                    t = linspace(0, constants.durationScale, constants.fs * constants.durationScale);
                    exconst = @(Duration) log(.0012)/Duration;

                    E(1,:) = A*exp(exconst(constants.durationScale) .* t);
                    osc(1,:) = E(1,:) .* sin(2*pi*startnote*.56.*t);

                    E(2,:) = A*.67*exp(exconst(constants.durationScale*.9) * t);
                    osc(2,:) = E(2,:) .* sin(2*pi*(startnote*.56 + 1).*t);

                    E(3,:) = A*exp(exconst(constants.durationScale*.65) * t);
                    osc(3,:) = E(3,:) .* sin(2*pi*(startnote*.92).*t);

                    E(4,:) = A*1.8*exp(exconst(constants.durationScale*.55) * t);
                    osc(4,:) = E(4,:) .* sin(2*pi*(startnote*.92 + 1.7).*t);

                    E(5,:) = A*2.67*exp(exconst(constants.durationScale*.325) * t);
                    osc(5,:) = E(5,:) .* sin(2*pi*(startnote*1.19).*t);

                    E(6,:) = A*1.67*exp(exconst(constants.durationScale*.35) * t);
                    osc(6,:) = E(6,:) .* sin(2*pi*(startnote*1.7).*t);

                    E(7,:) = A*1.46*exp(exconst(constants.durationScale*.25) * t);
                    osc(7,:) = E(7,:) .* sin(2*pi*(startnote*2).*t);

                    E(8,:) = A*1.33*exp(exconst(constants.durationScale*.2) * t);
                    osc(8,:) = E(8,:) .* sin(2*pi*(startnote*2.74).*t);

                    E(9,:) = A*1.33*exp(exconst(constants.durationScale*.15) * t);
                    osc(9,:) = E(9,:) .* sin(2*pi*(startnote*3).*t);

                    E(10,:) = A*exp(exconst(constants.durationScale*.1) * t);
                    osc(10,:) = E(10,:) .* sin(2*pi*(startnote*3.76).*t);

                    E(11,:) = A*1.33*exp(exconst(constants.durationScale*.075) * t);
                    osc(11,:) = E(11,:) .* sin(2*pi*(startnote*4.07).*t);

                    soundSample(:,k) = sum(osc);

                case {'Subtractive'}
                    %My poles spin around the origin
                    constants.durationScale = .5;
                    t = linspace(0, constants.durationScale, constants.fs * constants.durationScale);
                    Square = square(2*pi*startnote*t);
                    pole = .95;
                    filterLength = 2;
                    polerotate = linspace(3*pi/8,5*pi/8,(constants.fs * constants.durationScale)+filterLength); %0:pi/(constants.fs * constants.durationScale):pi;
                    Z(:,1) = pole * exp(1j.*polerotate.*(constants.durationScale)^-1);%Rotates pole from .75 to -.75
                    Z(:,2) = conj(Z(:,1));
                    Length = size(t);
                    y = zeros(1,Length(2)+filterLength);
                    Square = [Square zeros(1,filterLength)];
                    for index = 1+filterLength:Length(2)+filterLength-1
                        [b,a] = zp2tf([1],Z(index-filterLength,:),1);
                        y(index) = Square(index)- a(2)*y(index-1) - a(3)*y(index-2);
                    end
                    soundSample(:,k) = y;
                    %{
                    r = .75;
                    theta = linspace(0,pi,(constants.fs * constants.durationScale)/100);
                    for k = 1:(constants.fs * constants.durationScale)/100%Switch every 100 samples
                        angel = theta(k);
                        b = [0 0 1];
                        a = [1 -2*r*cos(angel) r^2];
                        y(100*(k-1)+1: k*100+1) = filter(b,a,Square(100*(k-1)+1: k*100+1));
                    end
                    plot(t(1:22001),y)
                    %}
                case {'FM'}
                    %FM from Fig 5.9 brass instrument
                    A = 1;
                    t = linspace(0, constants.durationScale, constants.fs * constants.durationScale);
                    time = constants.fs * constants.durationScale;
                    E1 =[ linspace(0,1,1/8 *time) linspace(1,.75,1/8 *time) linspace(.75,.7,1/2 *time) linspace(.7,0,(1/4 *time + 1))];
                    fm = startnote;
                    IMAX = 6;
                    F1 = E1*A;
                    F2 = IMAX.*E1;
                    FM_SIN = F2.*sin(2*pi.*fm.*t);
                    soundSample(:,k) = F1.* sin(2*pi*(startnote + FM_SIN).*t);
                case {'Waveshaper'}
                    %Waveshaper from Figure 5.31
                        constants.durationScale = .2;
                        A = 10;
                        time = constants.fs * constants.durationScale;
                        t = linspace(0, constants.durationScale, constants.fs * constants.durationScale);
                        E1 = [linspace(1,0,1/5 * time) zeros(1,time.*4/5)];
                        E2 = [linspace(0,1,1/5 * time) exp(-linspace(0,4,4/5 * time))];

                        sig2 = E2.*A.*sin(2*pi*startnote.*t);
                        sig1 = E1.*sin(2*pi*startnote*.7071.*t);
                        Fsig = 1+.841.*sig1 - .707.*sig1.^2 - .595.*sig1.^3 +.5.*sig1.^4 +.42.*sig1.^5 -.354.*sig1.^6 ...
                        -.297.*sig1.^7 +.25.*sig1.^8 +.21.*sig1.^9;
                        soundSample(:,k) = Fsig .* sig2;
                end               
        end
        soundSample = sum(soundSample,2);
        %plot(soundSample)
end