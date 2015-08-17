%                               Algorithm Comments

% Here is where we will implement the ant colony algorithm
% First we will identify all of the actors:
%    - k    : an ant
%    - r    : a current city (it is supposed that k is at r)
%    - s    : a destination city
%    - M_k  : the memory of ant k, keeps track of past visits
%    - tau  : pheremone vector such that tau(r, u) is the amount of
%             pheremone on edge (r, u) where r and u are cities
%    - eta  : A heuristic function which assigns some value to edges such
%             that eta(r, u) is the heuristic value of edge (r,u). For TSP,
%             this function is often the inverse distance between cities
%    - beta : A parameter which determines the weight of the heurstic
%             function eta
%    - q_0  : A parameter determining how often we take the route with the best
%             tau and eta values vs a random route
%    - S    : A random variable which is governed by the p_k distribution
%    - p_k  : The probability distribution of the variable S which favors
%             shorter edges and higher pheremones. p_k(r,s) is the probability
%             that ant k will choose to move from city r to city s
%    - rho  : the pheromone evaporation rate
%    - delta-tau: the global pheromone update rate
%    - Q    : constant that determines how to update tau

% Now a few formulas:

%     { argmax_{u \nin M_k} { tau(r,u) * eta(r,u)^{beta}    if q < q_0
% s = {
%     { S                                                     otherwise

%                     tau(r,s) * eta(r,s)^{beta}
%            {---------------------------------------------    if s \nin M_k
% p_k(r,s) = {sum_{u \nin m_k} (tau(r,u) * eta(r,u))^{beta}
%            {
% 		     {0                                                otherwise

% The algorithm proceeds in the following manner:
% while score_not_good_enough
%   for ant_k in colony
%     place ant_k at random city
%     while ant has not visited all cities
%         with probabily q_0, ant_k will move to the city with best tau and eta
%         otherwise, ant_k will move to a random city based on p_k
%     end
%
%     Perform pheremone update:
%     for edge in edge_set
%         if (edge is traversed)
%             tau(edge) = (1 - rho) * tau(edge) + delta-tau
%         else
%             tau(edge) = (1 - rho) * tau(edge)
%       end
%     end
%     If there is a score higher than currMax, update
%   end
% end
%

%    SETTING PARAMS     %
% exploit vs explore
q_0 = .7;
numAnts = 10;
beta = 2;
maxIts = 1000;
numCities = 1000;
Q = 1;
rho = .6;

fprintf('Running Ant Colony Optimization on %i cities with the following parameters:\n', numCities);
fprintf('numAnts = %d, q_0 = %3.3f, beta = %d, maxIts = %d, Q = %d, rho = %.3f\n', numAnts, q_0, beta, maxIts, Q, rho); 


% Create list of cities and plot (will simply be a circle for now)
cities = genCities(numCities, 'circ');
figure(1);
plot([cities(:).x],[cities(:).y], 'bo-')

% Tau will be populated dynamically, blank for now
tau = ones(numCities, numCities);

% Eta is a static matrix based on a known heuristic with known inputs
% so we can simply populate it now in advance
eta = genEta(cities);




bestPath = 1:numCities;
bestScore = scorePath(bestPath, cities);
fprintf('Initial Score: %f', bestScore);
numIts = 1;
scores = zeros(1, maxIts);

while numIts < maxIts;
	% for ant_k in colony
	for ant_k = 1:numAnts
		
		% Init empty path and place ant_k at a random starting index
		path = zeros(1, numCities);
		currInd = 1;
		path(currInd) = randi(numCities);
		
		% Need to track of where we have not been
		unvisited = 1:numCities;
		unvisited(path(1)) = [];
	
		
		% While ant has not visited all cities
		for currInd = 1:(numCities - 1)
			r = path(currInd);
			
			% Here we find the destination city s
			if (rand < q_0)
				[~, sInd] = max(tau(r, unvisited) .* eta(r, unvisited).^beta);
				s = unvisited(sInd);
			else
				vec = tau(r, unvisited) .* (eta(r, unvisited).^beta);
				probs = vec ./ sum(vec);
				
				% Draws the city to visit based on the above probabilities:
				%    The ways this works is that the ith element of probs
				%    defines the probability of selecting ith element of
				%    unvisited array. Thus if we want to draw an element
				%    based on this distribution, we treat the probabilities
				%    as a partitioning of the unit interval. We then choose
				%    a partition by generating a random number and then
				%    selecting the interval in which the number lies. By
				%    taking the cumulative sum of the probabilities, we get
				%    the partitions of the unit interval. We then compare
				%    this to the random number, the first nonzero element
				%    of the resulting logical array is the chosen element
				%    of the unvisited array
				sInd = find(cumsum(probs) > rand, 1);
				s = unvisited(sInd);
			end
			
			% Add s to the path and remove it from the unvisited list
			path(currInd + 1) =  s;
			unvisited(sInd) = [];
		end
		
		score = scorePath(path, cities);
		if (score < bestScore)
			bestScore = score;
			bestPath = path;
		end
		
		% Now we need to update tau with the pheromones left by this ant:
		toCities = circshift(path, [0,1]);
% 		tau(sub2ind([numCities numCities], path, toCities)) = tau(sub2ind([numCities numCities], path, toCities)) +  Q / score;
		
		for ind = 1:numCities
			fromCity = path(ind);
			toCity = toCities(ind);
			tau(fromCity, toCity) = tau(fromCity, toCity) + Q / score;
		end
	end
	
	scores(numIts) = bestScore;
	
	% Perform the pheromone evaporation
	tau = (1 - rho) * tau;
	
	numIts = numIts + 1;
end

disp(bestScore);
figure(2);
plot([cities(bestPath).x cities(bestPath(1)).x],  [cities(bestPath).y cities(bestPath(1)).y], 'bo-');

figure(3);
plot(1:maxIts, scores);


M_k = zeros(1, numCities);



