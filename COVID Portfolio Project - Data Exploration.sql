-- The first query orders the `CovidDeaths` table by columns 3 and 4 (likely `date` and another column), 
-- ensuring the data is sorted in a meaningful sequence for further analysis.

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

-- Updates data types for date/numerical columns in `CovidDeaths` and `CovidVaccines` to ensure they store appropriate data efficiently.

ALTER TABLE CovidDeaths
ALTER COLUMN date DATE;

ALTER TABLE CovidVaccinations
ALTER COLUMN date DATE;

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

-- Identifies rows where `population` contains invalid numeric data but isn't NULL, 
-- helping pinpoint and resolve data integrity issues.

SELECT population
FROM CovidDeaths
WHERE TRY_CAST(population AS NUMERIC) IS NULL AND population IS NOT NULL;

-- Updates `population` to NULL for rows where the data isn't valid as a number, 
-- ensuring consistency in this column.

UPDATE CovidDeaths
SET population = NULL
WHERE TRY_CAST(population AS NUMERIC) IS NULL;

-- Confirms there are no remaining invalid numeric values in `population` after the update.

SELECT population
FROM CovidDeaths
WHERE TRY_CAST(population AS NUMERIC) IS NULL;

-- Sets `continent` to NULL for rows with empty strings, ensuring this column only contains meaningful values.

UPDATE CovidDeaths
SET continent = NULL
WHERE TRIM(continent) = '';

-- Filters rows where `continent` is NOT NULL and reorders the data for cleaner and focused analysis.

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- Extracts selected columns from `CovidDeaths` for focused analysis. 
-- This includes core metrics like `location`, `date`, `total_cases`, `new_cases`, `total_deaths`, and `population`.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

-- Analyzes the fatality rate by calculating the percentage of deaths relative to total cases for countries with "states" in their name.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0 AND location LIKE '%states%'
ORDER BY 1,2;

-- Calculates the percentage of a country's population infected by dividing total cases by population.

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0
ORDER BY 1,2;

-- Identifies countries with the highest infection rate relative to their population.

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases)/population)*100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0
GROUP BY location, population
ORDER BY PercentOfPopulationInfected DESC;

-- Highlights countries with the highest death counts excluding aggregate regions like continents or unions.

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0 AND location NOT IN('World', 'Europe', 'North America', 'European Union', 'South America', 'Asia', 'Africa')
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Compares continents based on their total death counts.

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE total_cases>0 AND continent IS NOT NULL
GROUP BY continent 
ORDER BY TotalDeathCount DESC;

-- Computes global statistics for new cases and deaths, including the overall fatality rate.

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, 
SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE new_cases>0 AND continent IS NOT NULL
ORDER BY 1,2;

-- Aggregates daily global new cases and deaths, including the fatality rate by day.

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, 
SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE new_cases>0 AND continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Combines vaccination and death data to calculate cumulative vaccinations over time per location.

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CONVERT(INT, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date)
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location=v.location AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;

-- Uses a Common Table Expression to perform Calculation on Partition By in previous query

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CONVERT(INT, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, d.date)
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location=v.location AND d.date=v.date
WHERE d.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVsVac;

-- Creates a temporary table to calculate on Partition By in previous query

DROP TABLE IF exists #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);
INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, 
    TRY_CONVERT(NUMERIC, v.new_vaccinations) AS New_Vaccinations,
    SUM(TRY_CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Creates a view to save vaccination data for visualization in external tools.

CREATE VIEW PercentPopulationVaccinated AS 
SELECT d.continent, d.location, d.date, d.population, 
    TRY_CONVERT(NUMERIC, v.new_vaccinations) AS New_Vaccinations,
    SUM(TRY_CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
    ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated;
