/*

Covid 19 data exploration

Skills: Joins, CTE's, Temp Tables, Windows functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccionations
ORDER BY 3,4

-- Selecting the data that im gonna use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Total Cases vs Total Deaths in my Country
-- (Shows the evolution of the chances of dying from covid in Argentina)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS [Deaths Percentage]
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'argentina'
ORDER BY 2

-- Total Cases vs Population in Argentina
-- Shows the % of the population that got covid over time

SELECT location, date, population, total_cases, (total_cases/population)*100 AS [Infection Percentage]
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'argentina'
ORDER BY 2


-- Analyzing the Countries with the highest infection rates compared to population

SELECT location, population, MAX(total_cases) AS [Highest Infection Count], MAX((total_cases/population))*100 AS [Infection Percentage]
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

-- Showing the countries with the highest dead count per population
-- I had to cast total deaths as INT because i cant get the max number being a varchar

SELECT location, MAX(cast(total_deaths AS int)) AS [Total Deaths Count]
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

---- ANALYZING THE CONTINENTS

---- Highest Death Count by Continent

SELECT location, MAX(cast(total_deaths AS int)) AS [Total Deaths Count]
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY 2 DESC

-- Global Numbers Per day, and in second query are the global totals

SELECT date, SUM(new_cases) AS CasesPerDay, SUM(CAST(new_deaths AS INT)) AS DeathsPerDay, SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 AS [Deaths Percentage]
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

SELECT SUM(new_cases) AS CasesPerDay, SUM(CAST(new_deaths AS INT)) AS DeathsPerDay, SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 AS [Deaths Percentage]
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

-- Joineo ambas tablas para obtener mayor info, buscando asi el total de la poblacion y compararlo contra el total de vacunados.
-- A su vez, incluyo un rolling sum para el total de vacunados
-- Por ultimo para poder utilizar esta ultima funcion, puedo generar un CTE o un Temp Table para llegar al mismo resultado

-- CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccionations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageOfPeopleVaccinated
FROM PopvsVac

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccionations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageOfPeopleVaccinated
FROM #PercentPopulationVaccinated

--Creating a view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccionations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated