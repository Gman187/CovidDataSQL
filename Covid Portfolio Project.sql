-- Dataset we are pulling from is from the cdc website
-- https://ourworldindata.org/covid-deaths

-- Population Data
SELECT PercentUnitedStatesVaccinations
FROM [Portfolio Project]..CovidData

Select location
From [Portfolio Project]..CovidData
WHERE location = 'Upper middle income'


-- Comparing Total Cases vs. Total Deaths
-- Looking at the percent chance that someone who contracts Covid and likelyhood of death.
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS percent_deaths
From [Portfolio Project]..CovidData
WHERE location like '%states%'
ORDER BY 1,2

-- Covid Cases against total population
-- Percent of Population who have contracted Covid
Select Location, date, population,total_cases,(total_cases/population) * 100 AS percent_of_population_infected
From [Portfolio Project]..CovidData
WHERE location like '%states%'
ORDER BY 1,2

-- Comparing countries with Highest Covid Case count compared to Population

Select Location, Population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_of_population_infected
From [Portfolio Project]..CovidData
GROUP BY Location, Population
ORDER BY percent_of_population_infected DESC

-- Countries with the Highest Death Count per Population
Select Location, MAX(cast(total_deaths as int)) AS Total_Deaths 
From [Portfolio Project]..CovidData
-- WHERE location like '%states%'
WHERE continent is not null
GROUP BY Location
ORDER BY Total_Deaths DESC

-- Deaths per Continent
Select location, MAX(cast(total_deaths as int)) AS Total_Deaths 
From [Portfolio Project]..CovidData
-- Dataset lists income within the location column and a world total This query cleans it up.
WHERE continent is null AND location NOT IN ('Upper middle income', 'high income', 'lower middle income', 'low income', 'World', 'International') 
GROUP BY location
ORDER BY Total_Deaths DESC

-- Selecting Daily New Cases in the United States and comparing the overall death percent to daily death percent
SELECT date, SUM(new_cases) AS new_cases, SUM(cast(new_deaths as int)) AS new_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage, AVG(daily_average) as monthly_avg,location
FROM 
(SELECT SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS daily_average
 FROM [Portfolio Project]..CovidData
 WHERE date between '2021-12-01' AND '2021-12-26' AND location = 'United States') AS monthly_percent,
 [Portfolio Project]..CovidData
WHERE date between '2021-12-01' AND '2021-12-26' AND location = 'United States'
GROUP by date,location
ORDER BY 1,2,3

-- Looking at Total Vaccination by Continent vs Their Population
SELECT SUM(CAST(total_vaccinations as BIGINT)) AS vaccinations ,SUM(population) AS population 
FROM [Portfolio Project]..CovidData
WHERE total_vaccinations IS NOT NULL 
GROUP BY population,total_vaccinations
ORDER BY 1,2

-- Total Population vs. Vaccinations Using CTE
With 
	PopVac (Continent,Location, Population, new_vaccinations, RollingNewVaccinations)
AS
(
SELECT
	continent,location,population, new_vaccinations,
	SUM(Cast(new_vaccinations AS BIGINT)) OVER(PARTITION BY location ORDER BY location,date) AS RollingNewVaccinations
FROM 
	[Portfolio Project]..CovidData
WHERE 
	continent is not null
)
SELECT *,
	(RollingNewVaccinations/population)*100 AS percent_of_population_vaccinated
FROM PopVac

-- Using Temp Table for United States Vaccinations
DROP TABLE if exists #PercentUnitedStatesVaccination
CREATE TABLE
	#PercentUnitedStatesVaccination
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingNewVaccinations numeric
)

INSERT INTO #PercentUnitedStatesVaccination
SELECT continent,location,date,population, new_vaccinations,
	SUM(Cast(new_vaccinations AS BIGINT)) OVER(PARTITION BY location ORDER BY location,date) AS RollingNewVaccinations
FROM [Portfolio Project]..CovidData
WHERE new_vaccinations is not null AND location = 'United States'
GROUP BY location,population,date,continent,new_vaccinations
ORDER by 2,3
SELECT *,(RollingNewVaccinations/population)*100 AS percent_of_population_vaccinated
FROM #PercentUnitedStatesVaccination


-- Creating View to store data for Visualization
Create View PercentUnitedStatesVaccination AS
SELECT continent,location,date,population, new_vaccinations,
	SUM(Cast(new_vaccinations AS BIGINT)) OVER(PARTITION BY location ORDER BY location,date) AS RollingNewVaccinations
FROM [Portfolio Project]..CovidData
WHERE new_vaccinations is not null AND location = 'United States'
GROUP BY location,population,date,continent,new_vaccinations


