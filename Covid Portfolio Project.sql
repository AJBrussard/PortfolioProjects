SELECT *
FROM PortfolioProject..CovidDeaths

SELECT * 
FROM PortfolioProject..CovidVaccinations



-- Select relevant data
-------------------------------
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2


--Likelyhood of dying if contracting Covid in a given country
------------------------------------------------------------------
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,3) as deathsPercentage
FROM CovidDeaths
WHERE location = 'United States'
AND continent is not null
ORDER BY location, date


-- Looking at Total Cases vs Population in a given country
--------------------------------------------------------------
SELECT location, date, total_cases, population, ROUND((total_cases/population)*100,3) as percentPopulationWithCovid
FROM CovidDeaths
WHERE location = 'United States'
ORDER BY location, date


-- Which countries have the highest infection rates?
-------------------------------------------------------
SELECT location, population, MAX(total_cases) AS highestInfectedCount, ROUND((max(total_cases)/population)*100,5) as percentPopulationInfected
FROM CovidDeaths
WHERE continent is not null
group by location, population
ORDER BY percentPopulationInfected desc


-- Total deaths by continent
---------------------------------
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is null
group by location
ORDER BY TotalDeathCount desc


-- Which countries have the highest death count?
-------------------------------------------------
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
group by location
ORDER BY TotalDeathCount desc


-- Day-by-day Global Statistics
------------------------------------
SELECT date, SUM(new_cases) as newDailyGlobalCases, SUM(cast(new_deaths as int)) as newDailyGlobalDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as dailyDeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Total Population vs Vaccinations
---------------------------------------
SELECT	deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations as dailyVax,
		SUM(cast(vax.new_vaccinations as int)) OVER (Partition by deaths.location ORDER BY deaths.location,deaths.date) as totalVaxxed

FROM CovidDeaths deaths
JOIN CovidVaccinations vax
	ON deaths.location = vax.location
	and deaths.date = vax.date
WHERE deaths.continent is not null
ORDER BY location, date

 
-- CTE to calculate rolling vax percentage
----------------------------------------------
WITH PopVsVax (continent, location, date, population, new_vaccinations, totalVaxxed)
as
(
SELECT	deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations as dailyVax,
		SUM(cast(vax.new_vaccinations as int)) OVER (Partition by deaths.location ORDER BY deaths.location,deaths.date) as totalVaxxed
FROM CovidDeaths deaths
JOIN CovidVaccinations vax
	ON deaths.location = vax.location
	and deaths.date = vax.date
WHERE deaths.continent is not null
)
SELECT continent, location, date, population, new_vaccinations, totalVaxxed, ROUND(totalVaxxed/population*100,3) as percentPopVaccinated
FROM PopVsVax
WHERE continent is not NULL
ORDER BY location, date


-- Using Temp Table instead of CTE
-------------------------------------
DROP TABLE IF EXISTS #percentVaccinated
CREATE TABLE #percentVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
totalVaxxed numeric
)

INSERT INTO #percentVaccinated
SELECT	deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations as dailyVax,
		SUM(cast(vax.new_vaccinations as int)) OVER (Partition by deaths.location ORDER BY deaths.location,deaths.date) as totalVaxxed
FROM CovidDeaths deaths
JOIN CovidVaccinations vax
	ON deaths.location = vax.location
	and deaths.date = vax.date
WHERE deaths.continent is not null

SELECT *, ROUND(totalVaxxed/population*100,3) as percentPopVaccinated
FROM #percentVaccinated


-- Create a view
--------------------
CREATE VIEW TotalDeathsByCountry AS
(
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
group by location
)

SELECT *
FROM TotalDeathsByCountry
ORDER BY TotalDeathCount DESC