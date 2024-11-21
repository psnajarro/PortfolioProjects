
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

ALTER TABLE CovidDeaths
ALTER COLUMN date DATE;

ALTER TABLE CovidVaccinations
ALTER COLUMN date DATE;

SELECT population
FROM CovidDeaths
WHERE TRY_CAST(population AS NUMERIC) IS NULL AND population IS NOT NULL;

UPDATE CovidDeaths
SET population = NULL
WHERE TRY_CAST(population AS NUMERIC) IS NULL;

SELECT population
FROM CovidDeaths
WHERE TRY_CAST(population AS NUMERIC) IS NULL;

UPDATE CovidDeaths
SET continent = NULL
WHERE TRIM(continent) = ''

ALTER TABLE CovidDeaths
ALTER COLUMN population NUMERIC;

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths NUMERIC;

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases NUMERIC;

ALTER TABLE CovidDeaths
ALTER COLUMN new_cases INT;

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths NUMERIC;

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;


-- Looking at the totatl cases versus total deaths
-- Shows the chance of death if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0 AND location LIKE '%states%'
ORDER BY 1,2;


-- Looking at total cases versus population
--Shows what percentage of the population got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0 --AND location LIKE '%states%'
ORDER BY 1,2;


-- Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases)/population)*100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0 --AND location LIKE '%states%'
GROUP BY location, population
ORDER BY PercentOfPopulationInfected DESC;

-- Showing countries with the highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0 AND location NOT IN('World', 'Europe', 'North America', 'European Union', 'South America', 'Asia', 'Africa')
GROUP BY location
ORDER BY TotalDeathCount DESC;


--LETS BREAK THINGS DOWN BY CONTINENT
--Showing continents with the highest death count

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0 AND continent IS NOT NULL
GROUP BY continent 
ORDER BY TotalDeathCount DESC;




--GLOBAL NUMBERS


SELECT  SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, 
SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE new_cases>0 AND continent IS NOT NULL
--AND location LIKE '%states%'
--GROUP BY date
ORDER BY 1,2;

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, 
SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE new_cases>0 AND continent IS NOT NULL
--AND location LIKE '%states%'
GROUP BY date
ORDER BY 1,2;


-- Looking at total population vs vaccinations

SELECT d.continent, d.location, d.date,d.population, v.new_vaccinations,
	SUM(CONVERT(INT, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date)
	AS RollingPeopleVaccinated,
--	MAX(RollingPeopleVaccinated)/d.population)*100
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location=v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3


-- USE CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT d.continent, d.location, d.date,d.population, v.new_vaccinations,
	SUM(CONVERT(INT, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date)
	AS RollingPeopleVaccinated
--	,MAX(RollingPeopleVaccinated)/d.population)*100
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location=v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVsVac;




-- TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    New_Vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date,d.population, 
    TRY_CONVERT(NUMERIC, v.new_vaccinations) AS New_Vaccinations,
    SUM(TRY_CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;



-- Creating view to store data for later visualizations


CREATE View PercentPopulationVaccinated AS 
SELECT d.continent, d.location, d.date,d.population, 
    TRY_CONVERT(NUMERIC, v.new_vaccinations) AS New_Vaccinations,
    SUM(TRY_CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY 2,3;


SELECT *
FROM PercentPopulationVaccinated;